//
//  PostRepository.swift
//  mockup
//
//  Created by Studente on 18/07/24.
//

import Foundation

struct PostRepository {
    public static func getPosts() async throws -> [Post] {
        do {
            let req: (Data, URLResponse) = try await Rest.get(endPoint: "post")
            return try JSONDecoder().decode([Post].self, from: req.0)
        } catch {
            throw error
        }
    }
    
    public static func getPost(id: Int) async throws -> Post? {
        do {
            let req: (Data, URLResponse) = try await Rest.get(endPoint: "post?id=\(id)")
            return try JSONDecoder().decode(Post.self, from: req.0)
        } catch {
            throw error
        }
    }
    
    public static func getPostsByTravel(travelId: Int) async throws -> [Post] {
        do {
            let req: (Data, URLResponse) = try await Rest.get(endPoint: "post?trip=\(travelId)")
            return try JSONDecoder().decode([Post].self, from: req.0)
        } catch {
            throw error
        }
    }
    
    public struct PostData: Codable {
        let time: String
        let lat: Double?
        let lon: Double?
        let datatype: Int
        let trip: Int
        let user: Int
        let data: Data
    }

    public static func insertPost(data: PostData) async throws -> Post {
        let boundary = UUID().uuidString
        let parameters: [String: Any?] = [
            "time": data.time,
            "datatype": data.datatype,
            "trip": data.trip,
            "user": data.user,
            "lat": data.lat,
            "lon": data.lon
        ]
        
        let fileData = data.data
        let mimeType: String
        let fileExtension: String
        
        switch data.datatype {
        case 1:
            if isJPEG(data: fileData) {
                mimeType = "image/jpeg"
                fileExtension = ".jpg"
            } else if isPNG(data: fileData) {
                mimeType = "image/png"
                fileExtension = ".png"
            } else {
                mimeType = "application/octet-stream"
                fileExtension = ".bin"
            }
        case 2:
            mimeType = "video/mp4"
            fileExtension = ".mp4"
        default:
            mimeType = "application/octet-stream"
            fileExtension = ".bin"
        }
        
        do {
            let (responseData, response) = try await Rest.postMultipartFormData(
                endPoint: "post",
                parameters: parameters,
                filePathKey: "data",
                fileData: fileData,
                mimeType: mimeType,
                boundary: boundary,
                fileExtension: fileExtension
            )
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
                print("Failed with status code: \(httpResponse.statusCode)")
                print("Response: \(responseString)")
                throw URLError(.badServerResponse)
            }
            
            return try JSONDecoder().decode(Post.self, from: responseData)
            
        } catch {
            print("Error during insertPost: \(error.localizedDescription)")
            throw error
        }
    }

    private static func isJPEG(data: Data) -> Bool {
        let jpegSignature = Data([0xFF, 0xD8, 0xFF])
        return data.starts(with: jpegSignature)
    }

    private static func isPNG(data: Data) -> Bool {
        let pngSignature = Data([0x89, 0x50, 0x4E, 0x47])
        return data.starts(with: pngSignature)
    }
    
    public static func deletePost(post: Post, currentUser: User) async throws {
        let urlString = "post?postId=\(post.id)&userId=\(currentUser.id)"
        let (_, response) = try await Rest.delete(endPoint: urlString)

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                MediaDataModel.shared.reset(key: post)
            case 400:
                throw RestError.invalidParameters("Parametri non validi.")
            case 401:
                throw RestError.unauthorized("Non sei autorizzato a rimuovere il post.")
            default:
                throw RestError.unknown("Errore sconosciuto.")
            }
        } else {
            throw RestError.cannotConnect("Non sei connesso a internet.")
        }
    }
}
