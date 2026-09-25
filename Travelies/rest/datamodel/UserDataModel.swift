//
//  UserDataModel.swift
//  mockup
//
//  Created by Studente on 12/08/24.
//

import Foundation

public class UserDataModel : DataModel {
    typealias K = Int
    typealias T = User
    
    static let shared = UserDataModel()
    
    @Published private var byId: TCache<Int, User> = TCache()
    
    func getCurrentUser() -> User {
        return get(key: UserDefaults.standard.integer(forKey: "user_id"))!
    }

    func update(_ data: User?, withKey key: Int) {
        guard let data = data else {
            return
        }
        
        let _ = byId.set(data, forKey: key)
    }
    
    func reset(key: Int) {
        let _ = byId.set(nil, forKey: key)
    }
    
    func resetAll() {
        byId = TCache()
    }
    
    func get(key: Int) -> User? {
        byId.get(forKey: key)
    }
    
    func getAll() -> [User] {
        byId.values
    }
    
    func fetch(key: Int) async throws -> User? {
        if let user = get(key: key) {
            return user
        }
        
        do {
            let user = try await UserRepository.getUser(id: key)
            
            if user != nil {
                let _ = byId.set(user, forKey: key)
            }
            
            return user
        } catch {
            throw error
        }
    }
    
    func fetchAll() async throws -> [User] {
        guard !getAll().isEmpty else {
            return getAll()
        }
        
        do {
            let users = try await UserRepository.getUsers()
            
            for user in users {
                let _ = byId.set(user, forKey: user.id)
            }
            
            return users
        } catch {
            throw error
        }
    }
}
