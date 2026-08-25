import AVFoundation
import Foundation

actor LoopingPlaybackEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let varispeed = AVAudioUnitVarispeed()
    private let cache = SoundBufferCache()
    private var isGraphAttached = false
    private var currentResource: SoundResource?
    private var outputGain: Float = IntensityGrade.easy.rawValue
    private var playbackRate: Float = 0.5

    func warmup(resources: [SoundResource]) {
        attachGraphIfNeeded()
        cache.preload(resources, using: workingFormat)
        do {
            try AudioSessionConfigurator.activatePlaybackSession()
            engine.prepare()
        } catch {}
    }

    func play(_ resource: SoundResource) {
        halt(keepEngineRunning: true)
        attachGraphIfNeeded()

        do {
            try AudioSessionConfigurator.activatePlaybackSession()
        } catch {
            return
        }

        guard let buffer = cache.buffer(for: resource, using: workingFormat) else {
            return
        }

        reconnect(using: buffer.format)

        do {
            if !engine.isRunning {
                try engine.start()
            }
        } catch {
            return
        }

        currentResource = resource
        player.volume = outputGain
        varispeed.rate = Self.clampedRate(playbackRate)
        player.scheduleBuffer(buffer, at: nil, options: [.loops, .interrupts])
        player.play()
    }

    func halt(keepEngineRunning: Bool = false) {
        if player.isPlaying {
            player.stop()
        }
        player.reset()
        currentResource = nil

        if !keepEngineRunning {
            if engine.isRunning {
                engine.stop()
            }
            AudioSessionConfigurator.deactivatePlaybackSession()
        }
    }

    func applyRate(_ rate: Float) {
        playbackRate = rate
        varispeed.rate = Self.clampedRate(rate)
    }

    func applyGain(_ gain: Float) {
        outputGain = min(max(gain, 0), 1)
        player.volume = outputGain
    }

    func rebuildIfNeeded() {
        guard currentResource != nil || engine.isRunning else { return }
        attachGraphIfNeeded()
        if !engine.isRunning {
            engine.prepare()
            do {
                try engine.start()
            } catch {}
        }
    }

    private var workingFormat: AVAudioFormat {
        engine.mainMixerNode.outputFormat(forBus: 0)
    }

    private func attachGraphIfNeeded() {
        guard !isGraphAttached else { return }
        engine.attach(player)
        engine.attach(varispeed)
        isGraphAttached = true
        reconnect(using: workingFormat)
    }

    private func reconnect(using format: AVAudioFormat) {
        engine.disconnectNodeOutput(player)
        engine.disconnectNodeOutput(varispeed)
        engine.connect(player, to: varispeed, format: format)
        engine.connect(varispeed, to: engine.mainMixerNode, format: format)
    }

    private static func clampedRate(_ rate: Float) -> Float {
        min(max(rate, 0.25), 2.0)
    }
}
