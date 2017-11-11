//
//  KeychainToolTests.swift
//  KeychainToolTests
//
//  Created by Pedro Fonseca on 04/06/17.
//  Copyright © 2017 Pedro Fonseca. All rights reserved.
//

import XCTest
@testable import KeychainTool

class KeychainToolTests: XCTestCase {
    
    let key1 = "test.item1"
    let key2 = "test.item2"
    var data1: Data?
    var data2: Data?
    
    override func setUp() {
        super.setUp()

        data1 = randomBytes()
        data2 = randomBytes()
    }
    
    override func tearDown() {
        data1 = nil
        data2 = nil
        let query = [kSecClass as String: kSecClassGenericPassword]
        SecItemDelete(query as CFDictionary);
        
        super.tearDown()
    }
    
    func randomBytes() -> Data {
        let uuid = NSUUID.init()
        var bytes = [UInt8](repeating: 0, count: 16)
        uuid.getBytes(&bytes)
        return Data.init(bytes: bytes)
    }
    
    func testReadShouldThrowExceptionIfTheKeyIsMissing() {
        
        do {
            let _ = try KeychainTool.readValue(for: key1)
            XCTFail()
        } catch let KeychainToolError.notFound(k) where k == key1 {
            XCTAssertTrue(true)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testDeleteShouldThrowExceptionIfTheKeyIsMissing() {
        
        do {
            let _ = try KeychainTool.deleteValue(for: key1)
            XCTFail()
        } catch let KeychainToolError.notFound(k) where k == key1 {
            XCTAssertTrue(true)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testWriteShouldAddItemToTheKeychain() {
        
        do {
            try KeychainTool.write(value: data1!, for: key1)
            
            guard let outAttributes = try KeychainTool.findAttributes(for: key1),
                let account = outAttributes[kSecAttrAccount as String] else {
                XCTFail("Failed to find the item with the key \(key1).")
                return
            }
            XCTAssertTrue((account as! String) == key1)
            
            let outValue = try KeychainTool.readValue(for: key1)
            XCTAssertEqual(data1, outValue)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testDeleteShouldRemoveAPreviouslyAddedItemFromTheKeychain() {

        do {
            try KeychainTool.write(value: data1!, for: key1)
            try KeychainTool.deleteValue(for: key1)
        
            do {
                let _ = try KeychainTool.readValue(for: key1)
                XCTFail()
            } catch KeychainToolError.notFound {
                XCTAssertTrue(true)
            } catch {
                XCTFail("\(error)")
            }

        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testWritesWithDifferentKeysShouldAddDifferentItems() {
        
        do {
            try KeychainTool.write(value: data1!, for: key1)
            try KeychainTool.write(value: data1!, for: key2)
            
            let count = KeychainTool.count()
            XCTAssert(count == 2, "Expected 2 items in the keychain, found \(count)")
            
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testWritesWithTheSameKeyShouldUpdateTheKeychain() {
        
        do {
            try KeychainTool.write(value: data1!, for: key1)
            try KeychainTool.write(value: data2!, for: key1)
            
            let count = KeychainTool.count()
            XCTAssert(count == 1, "Expected 1 item in the keychain, found \(count)")
            
            let outValue = try KeychainTool.readValue(for: key1)
            XCTAssertEqual(data2, outValue)
            
        } catch {
            XCTFail("\(error)")
        }
    }
}
