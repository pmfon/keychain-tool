//
//  KeychainTool.swift
//  KeychainTool
//
//  Created by Pedro Fonseca on 28/05/17.
//  Copyright © 2017 Pedro Fonseca. All rights reserved.
//

import Foundation


public enum KeychainToolError: Error {
    case notFound(String)
    case apiError(Int32)
}


public class KeychainTool {

    private static var attrSynchronizable = kCFBooleanFalse
    public static var synchronizable: Bool {
        set {
            attrSynchronizable = newValue ? kCFBooleanTrue : kCFBooleanFalse
        }
        get {
            return attrSynchronizable! == kCFBooleanTrue
        }
    }


    // MARK: -
    
    public static func write(value: Data, for key: String) throws {
    
        var query = searchAttributes(for: key)
        
        var status = errSecSuccess
        if let _ = try? readValue(for: key) {
            let updatedAttributes = [kSecValueData as String: value as AnyObject]
            status = SecItemUpdate(query as CFDictionary, updatedAttributes as CFDictionary)
        } else {
            query[kSecValueData as String] = value as AnyObject
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        if status != errSecSuccess {
            throw KeychainToolError.apiError(status)
        }
    }
    
    public static func readValue(for key: String) throws -> Data? {
    
        var result: AnyObject?
        var query = searchAttributes(for: key)
        query[kSecReturnData as String] = kCFBooleanTrue

        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            throw KeychainToolError.notFound(key)
        default:
            throw KeychainToolError.apiError(status)
        }
    }
    
    public static func deleteValue(for key: String) throws {

        let query = searchAttributes(for: key)
        
        let status = SecItemDelete(query as CFDictionary)

        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw KeychainToolError.notFound(key)
        default:
            throw KeychainToolError.apiError(status)
        }
    }
    
    
    // MARK: -
    
    internal static func findAttributes(for key: String) throws -> [String: AnyObject]? {
        
        var attributes: AnyObject?
        var query = searchAttributes(for: key)
        query[kSecReturnAttributes as String] = kCFBooleanTrue

        let status = SecItemCopyMatching(query as CFDictionary, &attributes)
        
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw KeychainToolError.notFound(key)
        default:
            throw KeychainToolError.apiError(status)
        }

        return attributes as? [String: AnyObject]
    }
    
    internal static func count() -> Int {
     
        var results: AnyObject?
        var query = searchAttributes()
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        
        let status = SecItemCopyMatching(query as CFDictionary, &results)

        if status == errSecSuccess,
            let results = results as? [AnyObject] {
            return results.count
        }
        
        return 0
    }
    
    private static func searchAttributes(for account: String? = nil) -> [String: AnyObject] {

        var attributes: [String: AnyObject] = [
            kSecClass as String              : kSecClassGenericPassword,
            kSecAttrSynchronizable as String : attrSynchronizable!
        ]

        if let account = account as AnyObject? {
            attributes[kSecAttrAccount as String] = account
        }
        
        return attributes
    }
}
