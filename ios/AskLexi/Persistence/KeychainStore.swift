import Foundation
import Security

/// Minimal, dependency-free Keychain wrapper for small secrets (auth tokens).
///
/// Values are stored as generic passwords keyed by `account`, scoped to a fixed
/// `service`. Accessibility is `afterFirstUnlock` so tokens survive relaunch but
/// aren't readable before first unlock.
struct KeychainStore {
    enum KeychainError: Error, Equatable {
        case unexpectedStatus(OSStatus)
    }

    let service: String

    init(service: String = "legal.asklexi.app") {
        self.service = service
    }

    // MARK: Data

    func set(_ data: Data, for account: String) throws {
        // Upsert: try update first, insert if not found.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        if updateStatus == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(insert as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
            return
        }
        throw KeychainError.unexpectedStatus(updateStatus)
    }

    func data(for account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    @discardableResult
    func remove(_ account: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
        return status == errSecSuccess
    }

    // MARK: String convenience

    func setString(_ string: String, for account: String) throws {
        try set(Data(string.utf8), for: account)
    }

    func string(for account: String) throws -> String? {
        guard let data = try data(for: account) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: Codable convenience

    func setCodable<T: Encodable>(_ value: T, for account: String) throws {
        try set(try JSONEncoder().encode(value), for: account)
    }

    func codable<T: Decodable>(_ type: T.Type, for account: String) throws -> T? {
        guard let data = try data(for: account) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
