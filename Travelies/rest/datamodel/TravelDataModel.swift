//
//  PostDataModel.swift
//  mockup
//
//  Created by Studente on 09/08/24.
//

import Foundation

public class TravelDataModel: DataModel {
    typealias K = Int
    typealias T = Travel
    
    static let shared = TravelDataModel()
    
    @Published private var byId     : TCache<Int, Travel>    = TCache()
    
    func reset(key: Int) {
        let _ = byId.set(nil, forKey: key)
    }
    
    func resetAll() {
        byId = TCache()
    }
        
    func update(_ data: Travel?, withKey key: Int) {
        guard let travel = data else {
            return
        }
        
        let _ = byId.set(travel, forKey: key)
    }
    
    func get(key: Int) -> Travel? {
        byId.get(forKey: key)
    }
    
    func getAll() -> [Travel] {
        byId.values
    }
    
    func getByUserId(userId: Int) -> [Travel] {
        byId.values
            .filter({ $0.creator.id == userId || $0.isMember(userId: userId) })
            .compactMap({ $0 })
    }
    
    func removeTravel(travelId: Int) {
        guard let travel = byId.get(forKey: travelId) else {
            return
        }

        let _ = byId.set(nil, forKey: travelId)
    }
    
    func fetch(key: Int) async throws -> Travel? {
        if let travel = byId.get(forKey: key) {
            return travel
        }
        
        do {
            let travel = try await TravelRepository.getTravel(id: key)
            
            if let travel = travel {
                let _ = byId.set(travel, forKey: key)
            }
            
            return travel
        } catch {
            throw error
        }
    }
    
    func fetchAll(userId: Int) async throws -> [Travel] {
        guard !getByUserId(userId: userId).isEmpty else {
            return getByUserId(userId: userId)
        }
                
        do {
            let travels = try await TravelRepository.getTravelsByUser(userId: userId)
            
            for travel in travels {
                let _ = byId.set(travel, forKey: travel.id)
            }
            
            return travels
        } catch {
            throw error
        }
    }

    func fetchAll() async throws -> [Travel] {
        guard !byId.isEmpty else {
            return byId.values
        }
        
        do {
            let travels = try await TravelRepository.getTravels()

            for travel in travels {
                let _ = byId.set(travel, forKey: travel.id)
            }
            
            return travels
        } catch {
            throw error
        }
    }
}
