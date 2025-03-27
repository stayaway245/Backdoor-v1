//
//  KeychainManager.swift
//  feather
//
//  Created on 3/27/25.
//  Copyright (c) 2025
//

import Foundation
import Security

/// Utility for securely storing and retrieving sensitive information in the keychain
final class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
    }
    
    /// Save a string value to the keychain
    func saveString(_ string: String, forKey key: String) throws {
        // Convert string to data
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unexpectedStatus(errSecParam)
        }
        
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Retrieve a string value from the keychain
    func getString(forKey key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = dataTypeRef as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedStatus(errSecParam)
        }
        
        return string
    }
    
    /// Delete a value from the keychain
    func deleteValue(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
