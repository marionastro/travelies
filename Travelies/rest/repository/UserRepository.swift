//
//  UserRepository.swift
//  mockup
//
//  Created by Studente on 18/07/24.
//

import Foundation

struct UserRepository {
    public static func getUsers() async throws -> Array<User> {
        do {
            let req: (Data, URLResponse) = try await Rest.get(endPoint: "user")
            return try JSONDecoder().decode(Array<User>.self, from: req.0)
        } catch {
            throw error
        }
    }
    
    public static func getUser(id: Int) async throws -> User? {
        do {
            let req: (Data, URLResponse) = try await Rest.get(endPoint: "user?id=\(id)")
            return try JSONDecoder().decode(User.self, from: req.0)
        } catch {
            throw error
        }
    }
    
    public static func getUsersByTravel(travelId: Int) async throws -> Array<User> {
        do {
            let req: (Data, URLResponse) = try await Rest.get(endPoint: "user?trip=\(travelId)")
            return try JSONDecoder().decode(Array<User>.self, from: req.0)
        } catch {
            throw error
        }
    }
    
    public static func deleteFriend(fromId: Int, toId: Int) async throws {
        let (_, response) = try await Rest.delete(endPoint: "friend?fromId=\(fromId)&toId=\(toId)")

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                if var from = UserDataModel.shared.get(key: fromId),
                   var to = UserDataModel.shared.get(key: toId) {
                    from.removeFriend(friend: to)
                    to.removeFriend(friend: from)
                    
                    UserDataModel.shared.update(from, withKey: fromId)
                    UserDataModel.shared.update(to, withKey: toId)
                }
            case 400:
                throw RestError.invalidParameters("Parametri non validi.")
            default:
                throw RestError.unknown("Errore sconosciuto.")
            }
        }
    }
    
    public static func handleInvitation(invitationCode: String) async throws {
        let userId = UserDataModel.shared.getCurrentUser().id
        let parameters: [String: Any] = ["invite": invitationCode, "fromId": userId]

        let (data, response) = try await Rest.postFormEncoded(endPoint: "friend", data: parameters)

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                if let toIdString = String(data: data, encoding: .utf8),
                   let toId = Int(toIdString) {

                    if var to = UserDataModel.shared.get(key: toId),
                       var from = UserDataModel.shared.get(key: userId) {
                        to.addFriend(friend: from)
                        from.addFriend(friend: to)
                        
                        UserDataModel.shared.update(to, withKey: toId)
                        UserDataModel.shared.update(from, withKey: userId)
                    }
                } else {
                    throw RestError.notFound("Invito scaduto o non esistente.")
                }
            case 404:
                throw RestError.notFound("Invito scaduto o inesistente.")
            case 400:
                throw RestError.invalidParameters("Sei il proprietario dell'invito.")
            default:
                throw RestError.unknown("Errore sconosciuto.")
            }
        }
    }
}
