//
//  TravelRepository.swift
//  mockup
//
//  Created by Studente on 18/07/24.
//

import Foundation

struct TravelRepository {
    public static func getTravels() async throws -> [Travel] {
        do {
            let req: (Data, URLResponse) = try await Rest.get(endPoint: "trip")
            return try JSONDecoder().decode([Travel].self, from: req.0)
        } catch {
            throw error
        }
    }
    
    public static func getTravel(id: Int) async throws -> Travel? {
        do {
            let req: (Data, URLResponse) = try await Rest.get(endPoint: "trip?id=\(id)")
            return try JSONDecoder().decode(Travel.self, from: req.0)
        } catch {
            throw error
        }
    }
    
    public static func getTravelsByUser(userId: Int) async throws -> [Travel] {
        do {
            let req: (Data, URLResponse) = try await Rest.get(endPoint: "trip?user=\(userId)")
            return try JSONDecoder().decode([Travel].self, from: req.0)
        } catch {
            throw error
        }
    }
    
    public struct TravelPostData: Codable {
        let name: String
        let creator: Int
        let privacy: Int
    }
    
    public static func insertTravel(data: TravelPostData) async throws -> Travel {
        do {
            let parameters: [String: Any] = [
                "name": data.name,
                "creator": data.creator,
                "privacy": data.privacy
            ]
            
            let (responseData, response) = try await Rest.postFormEncoded(endPoint: "trip", data: parameters)
            
            if let jsonString = String(data: responseData, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw URLError(.badServerResponse)
            }
            
            let travel = try JSONDecoder().decode(Travel.self, from: responseData)
            
            TravelDataModel.shared.update(travel, withKey: travel.id)
            
            return travel
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
    
    public static func deleteTravel(travelId: Int, userId: Int) async throws {
        do {
            let (_, response) = try await Rest.delete(endPoint: "trip?tripId=\(travelId)&userId=\(userId)")

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {

                TravelDataModel.shared.removeTravel(travelId: travelId)
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            throw error
        }
    }
    
    public static func editTravel(tripId: Int, userId: Int, privacy: Int) async throws {
        do {
            let (responseData, response) = try await Rest.patch(endPoint: "trip?tripId=\(tripId)&userId=\(userId)&privacy=\(privacy)")
            
            if let jsonString = String(data: responseData, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw URLError(.badServerResponse)
            }
            
            if responseData.isEmpty {
                throw URLError(.cannotParseResponse)
            }
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
    
    public static func deletePartecipante(tripId: Int, creatorId: Int, userId: Int) async throws {
        let (_, response) = try await Rest.delete(endPoint: "join?tripId=\(tripId)&creatorId=\(creatorId)&userId=\(userId)")

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                if var travel = TravelDataModel.shared.get(key: tripId),
                   let user = UserDataModel.shared.get(key: userId) {
                    travel.removeMember(member: user)
                    
                    TravelDataModel.shared.update(travel, withKey: tripId)
                }
            case 400:
                throw RestError.invalidParameters("Sei il creatore del viaggio.")
            case 401:
                throw RestError.invalidParameters("Non sei autorizzato a rimuovere un partecipante dal viaggio.")
            default:
                throw RestError.unknown("Errore sconosciuto.")
            }
        }
    }
    
    public static func handleParticipation(invitationCode: String) async throws {
        let userId = UserDataModel.shared.getCurrentUser().id
        let parameters: [String: Any] = ["invite": invitationCode, "fromId": userId]
        
        let (data, response) = try await Rest.postFormEncoded(endPoint: "join", data: parameters)
        
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                if let idString = String(data: data, encoding: .utf8),
                   let travelId = Int(idString) {

                    if var travel = TravelDataModel.shared.get(key: travelId),
                       let user = UserDataModel.shared.get(key: userId) {
                        travel.addMember(member: user)
                        
                        TravelDataModel.shared.update(travel, withKey: travelId)
                    }
                } else {
                    throw RestError.notFound("Invito scaduto o inesistente.")
                }
            case 404:
                throw RestError.notFound("Invito scaduto o inesistente.")
            case 400:
                throw RestError.invalidParameters("Sei il creatore del viaggio.")
            default:
                throw RestError.unknown("Errore sconosciuto.")
            }
        }
    }
}
