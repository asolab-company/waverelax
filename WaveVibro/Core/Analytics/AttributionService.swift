import AppTrackingTransparency
import AppsFlyerLib
import UIKit

@MainActor
final class AttributionService {
    static let shared = AttributionService()
    private var isConfigured = false
    private var sessionReady = false
    private var isRequestingATT = false
    private var hasStartedForegroundSession = false
    var canLogEvents: Bool { isConfigured && hasStartedForegroundSession }

    private init() {}

    func configure(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard !isConfigured, !AppConfiguration.Analytics.appsFlyerDevKey.isEmpty else { return }
        isConfigured = true
        let sdk = AppsFlyerLib.shared()
        sdk.isDebug = false
        #if targetEnvironment(simulator)
        sdk.useReceiptValidationSandbox = true
        #else
        sdk.useReceiptValidationSandbox = false
        #endif
        sdk.useUninstallSandbox = false
        sdk.initialize(
            devKey: AppConfiguration.Analytics.appsFlyerDevKey,
            appId: AppConfiguration.Analytics.appleAppID
        )
        sdk.handleLaunchOptions(launchOptions)
        sdk.registerSessionReadyListener { [weak self] in
            Task { @MainActor [weak self] in
                self?.sessionReady = true
                self?.startSessionIfReady()
            }
        }
    }

    func applicationDidBecomeActive() {
        guard !isRequestingATT else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            startSessionIfReady()
            return
        }
        guard UIApplication.shared.applicationState == .active else { return }
        isRequestingATT = true
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isRequestingATT = false
                AnalyticsService.shared.track("Tracking Permission Result", properties: [
                    "status": Self.statusName(status)
                ])
                self.startSessionIfReady()
                SubscriptionAnalyticsService.shared.start()
            }
        }
    }

    func applicationDidEnterBackground() {
        hasStartedForegroundSession = false
        sessionReady = false
    }

    private func startSessionIfReady() {
        guard isConfigured, sessionReady, !isRequestingATT, !hasStartedForegroundSession,
              UIApplication.shared.applicationState == .active,
              ATTrackingManager.trackingAuthorizationStatus != .notDetermined
        else { return }
        sessionReady = false
        hasStartedForegroundSession = true
        AppsFlyerLib.shared().start()
        SubscriptionAnalyticsService.shared.flushAttributionEvents()
        Task { await AdaptyService.shared.syncIdentifiers() }
    }

    private static func statusName(_ status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .authorized: "authorized"
        case .denied: "denied"
        case .restricted: "restricted"
        case .notDetermined: "not_determined"
        @unknown default: "unknown"
        }
    }
}
