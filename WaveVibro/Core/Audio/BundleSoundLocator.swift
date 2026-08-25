import Foundation

enum BundleSoundLocator {
    static func url(for resource: SoundResource) -> URL? {
        let bundle = Bundle.main
        let folders = ["Resources/Audio", "Audio"]

        for folder in folders {
            if let url = bundle.url(
                forResource: resource.fileName,
                withExtension: resource.fileExtension,
                subdirectory: folder
            ) {
                return url
            }
        }

        return bundle.url(
            forResource: resource.fileName,
            withExtension: resource.fileExtension
        )
    }
}
