import Foundation

struct WebSubscriptionState: Decodable {
    struct Entitlement: Decodable {
        let active: Bool
        let expiresAt: String?
    }
    let applicationId: String
    let useWebPaywall: Bool
    let entitlement: Entitlement
}
@MainActor
final class WebSubscriptionClient {
    static let shared = WebSubscriptionClient()
    private let baseURL = AppConfiguration.WebService.baseURL
    private let credentials = InstallationCredentialStore()
    private let session: URLSession

    init(session: URLSession = .shared) { self.session = session }

    func refresh() async throws -> WebSubscriptionState {
        let state: WebSubscriptionState = try await request("api/app/session", method: "POST", body: nil)
        guard state.applicationId == AppConfiguration.WebService.applicationID else { throw URLError(.badServerResponse) }
        return state
    }

    func launch(restore: Bool = false, onboarding: Bool = false) async throws -> URL {
        struct Launch: Decodable { let url: URL; let commerceMode: String?; let applicationId: String? }
        let result: Launch = try await request("api/app/launch", method: "POST", body: ["restore": restore, "onboarding": onboarding])
        guard result.applicationId == AppConfiguration.WebService.applicationID, result.commerceMode == "live", result.url.scheme == baseURL.scheme, result.url.host == baseURL.host, result.url.port == baseURL.port,
              result.url.path == "/api/app/launch",
              URLComponents(url: result.url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "app" })?.value == AppConfiguration.WebService.applicationID
        else { throw URLError(.badServerResponse) }
        return result.url
    }

    private func request<T: Decodable>(_ path: String, method: String, body: [String: Bool]?) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "app", value: AppConfiguration.WebService.applicationID)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.timeoutInterval = 12
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bearer \(try credentials.value())", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

}
