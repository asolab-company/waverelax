import AVFoundation
import Foundation

final class SoundBufferCache: @unchecked Sendable {
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private let lock = NSLock()

    func preload(_ resources: [SoundResource], using format: AVAudioFormat) {
        for resource in resources {
            _ = buffer(for: resource, using: format)
        }
    }

    func buffer(for resource: SoundResource, using format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let key = "\(resource.fileName).\(resource.fileExtension)"

        lock.lock()
        if let existing = buffers[key] {
            lock.unlock()
            return existing
        }
        lock.unlock()

        guard
            let url = BundleSoundLocator.url(for: resource),
            let file = try? AVAudioFile(forReading: url),
            let converted = convert(file, to: format)
        else {
            return nil
        }

        lock.lock()
        buffers[key] = converted
        lock.unlock()
        return converted
    }

    private func convert(_ file: AVAudioFile, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(file.length)
        guard
            let sourceBuffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: frameCount
            )
        else {
            return nil
        }

        do {
            try file.read(into: sourceBuffer)
        } catch {
            return nil
        }

        if file.processingFormat == format {
            return sourceBuffer
        }

        guard let converter = AVAudioConverter(from: file.processingFormat, to: format) else {
            return nil
        }

        let ratio = format.sampleRate / file.processingFormat.sampleRate
        let convertedCapacity = AVAudioFrameCount(Double(sourceBuffer.frameLength) * ratio) + 1
        guard let converted = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: convertedCapacity) else {
            return nil
        }

        var consumed = false
        let inputBlock: AVAudioConverterInputBlock = { _, status in
            if consumed {
                status.pointee = .endOfStream
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return sourceBuffer
        }

        var conversionError: NSError?
        converter.convert(to: converted, error: &conversionError, withInputFrom: inputBlock)
        return conversionError == nil ? converted : nil
    }
}
