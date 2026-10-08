import AmplitudeSwift
import Foundation

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()
    private var amplitude: Amplitude?

    private init() {}

    func configure() {
        guard amplitude == nil, !AppConfiguration.Analytics.amplitudeAPIKey.isEmpty else { return }

        amplitude = Amplitude(configuration: Configuration(
            apiKey: AppConfiguration.Analytics.amplitudeAPIKey,
            logLevel: .off,
            autocapture: [.sessions, .appLifecycles],
            enableAutoCaptureRemoteConfig: false
        ))
    }

    var deviceID: String? { amplitude?.getDeviceId() }

    @discardableResult
    func track(_ event: String, properties: [String: Any] = [:]) -> Bool {
        configure()
        guard let amplitude else { return false }
        var metadata = properties
        metadata["build_type"] = "release"
        metadata["application_id"] = "wavevibro"
        amplitude.track(eventType: event, eventProperties: metadata)
        return true
    }

    func flush() {
        amplitude?.flush()
    }
}
