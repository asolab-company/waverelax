import Foundation

enum AppConfiguration {
    enum WebService {
        static let baseURL = URL(string: "https://www.origino.space")!
        static let applicationID = "wavevibro"
    }
    enum Analytics {
        static let appleAppID = "6805003674"
        static var appsFlyerDevKey: String { configured("WaveAppsFlyerDevKey") }
        static var amplitudeAPIKey: String { configured("WaveAmplitudeAPIKey") }
        private static func configured(_ key: String) -> String {
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
            return value.hasPrefix("$(") ? "" : value
        }
    }
    enum StoreKit {
        static let premiumProductIDs = [ProductIdentity.weekly, ProductIdentity.yearly]
    }
}
