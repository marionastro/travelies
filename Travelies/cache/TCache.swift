//
//  TCache.swift
//  mockup
//
//  Created by Studente on 18/08/24.
//

import Foundation

public class TCache<Key: Hashable, Value> {
    private var items: [Key: Value] = [:]
    private let lock: NSLock = .init()
    
    public func set(_ value: Value?, forKey key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        guard let value = value else {
            items.removeValue(forKey: key)
            return nil
        }
        
        items.updateValue(value, forKey: key)
        return items[key]
    }
    
    public func get(forKey key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return items[key]
    }
    
    public func contains(withKey key: Key) -> Bool {
        items.contains { $0.key == key }
    }
    
    public var values: [Value] {
        return Array(items.values)
    }
    
    public var keys: [Key] {
        return Array(items.keys)
    }
    
    public var count: Int {
        return items.count
    }
    
    public var isEmpty: Bool {
        return items.isEmpty
    }
}
