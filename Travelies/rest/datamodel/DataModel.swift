//
//  DataModel.swift
//  mockup
//
//  Created by Studente on 12/08/24.
//

import Foundation

protocol DataModel : ObservableObject {
    associatedtype K
    associatedtype T
    
    // Force update cached data
    
    func update(_ data: T?, withKey key: K)
    
    // Functions-Set to reset cached data
        
    func reset(key: K)
    
    func resetAll()
    
    // Functions-Set to get cached data
    
    func get(key: K) -> T?
    
    func getAll() -> [T]
    
    // Functions-Set to retrieve data to cache
    
    func fetch(key: K) async throws -> T?
}

extension DataModel {
    @available(*, unavailable)
    func fetchAll() async throws -> [T] {
        return []
    }
}
