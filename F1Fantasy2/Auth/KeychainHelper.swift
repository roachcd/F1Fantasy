//
//  KeychainHelper.swift
//  F1FantasyIOS
//
//  Created by Chase Roach on 3/12/26.
//

import Security
import Foundation


/// A helper class for securely storing, retreiving and deleting the users login token.
///
/// Usage:
/// ```swift
/// KeychainHelper.shared.save("token", for: "authToken")
/// let token = KeychainHelper.shared.read(for: "authToken)
/// KeychainHelper.shared.delete(for: "authToken")
/// ```
final class KeychainHelper {
    /// Singleton for KeychainHelper
    static let shared = KeychainHelper()
    private init() {}

    /// Saves a string value in the Keychain for a given key.
    ///
    /// If a value already exists for the provided key, it will be overwritten.
    ///
    /// - Parameters:
    ///   - value: The string value to store securely.
    ///   - key: A unique identifier used to store and retrieve the value.
    func save(_ value: String, for key: String) {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        // Remove any existing item before saving a new one
        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemAdd(attributes as CFDictionary, nil)
    }

    /// Reads a string value from the Keychain for a given key.
    ///
    /// - Parameter key: The key associated with the stored value.
    /// - Returns: The stored string if found and decodable, otherwise `nil`.
    func read(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    /// Deletes a value from the Keychain for a given key.
    ///
    /// - Parameter key: The key associated with the value to delete.
    func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
