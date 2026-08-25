import Foundation

struct SoundResource: Hashable, Sendable {
    let fileName: String
    let fileExtension: String

    static func bundledLoop(_ fileName: String) -> SoundResource {
        SoundResource(fileName: fileName, fileExtension: "wav")
    }
}
