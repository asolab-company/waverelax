import Foundation
import Security

@MainActor
final class InstallationCredentialStore {
    private var token: String?

    func value() throws -> String {
        if let token { return token }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: "com.waverelax.web-subscription",
                                   kSecAttrAccount as String: "installation"]
        var read = query
        read[kSecReturnData as String] = true
        read[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(read as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data,
           let stored = String(data: data, encoding: .utf8), stored.count == 64 {
            token = stored
            return stored
        }
        guard status == errSecItemNotFound else { throw URLError(.userAuthenticationRequired) }
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { throw URLError(.unknown) }
        let created = bytes.map { String(format: "%02x", $0) }.joined()
        var add = query
        add[kSecValueData as String] = Data(created.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(add as CFDictionary, nil) == errSecSuccess else { throw URLError(.cannotCreateFile) }
        token = created
        return created
    }
}
