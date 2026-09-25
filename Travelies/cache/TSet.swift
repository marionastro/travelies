//
//  TSet.swift
//  mockup
//
//  Created by Studente on 19/08/24.
//

import Foundation


import Foundation

public struct TSet<T: Hashable> {
    private var elements: Set<T> = []
    private let lock: NSLock = .init()

    mutating func insert(_ value: T) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return elements.insert(value).0
    }

    mutating func remove(_ member: T) {
        lock.lock()
        defer { lock.unlock() }
        elements.remove(member)
    }
    
    func contains(_ member: T) -> Bool {
        elements.contains(member)
    }
    
    var values: [T] {
        return Array(elements)
    }
}
