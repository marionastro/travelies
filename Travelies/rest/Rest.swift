//
//  API.swift
//  mockup
//
//  Created by Studente on 18/07/24.
//

import Foundation

struct Rest {
    public static let URL = "http://149.202.38.175"
    
    public static func get(endPoint: String) async throws -> (Data, URLResponse) {
        let url = Foundation.URL(string: "\(URL)/\(endPoint)")!
        return try await URLSession.shared.data(from: url)
    }
    
    public static func postFormEncoded(endPoint: String, data: [String: Any], params: URLQueryItem...) async throws -> (Data, URLResponse) {
        var urlComponents = URLComponents(string: "\(URL)/\(endPoint)")!
        urlComponents.queryItems = params
        
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        
        let bodyData = data.percentEncoded()
        request.httpBody = bodyData
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
            print("HTTP Headers: \(httpResponse.allHeaderFields)")
        }
        
        return (responseData, response)
    }
    
    public static func postMultipartFormData(endPoint: String, parameters: [String: Any?], filePathKey: String, fileData: Data, mimeType: String, boundary: String, fileExtension: String) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: Foundation.URL(string: "\(URL)/\(endPoint)")!)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let body = createBodyWithParameters(parameters: parameters, filePathKey: filePathKey, fileData: fileData, mimeType: mimeType, boundary: boundary, fileExtension: fileExtension)
        request.httpBody = body
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
            print("HTTP Headers: \(httpResponse.allHeaderFields)")
            if !(200...299).contains(httpResponse.statusCode) {
                let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
                print("Failed with status code: \(httpResponse.statusCode)")
                print("Response: \(responseString)")
                throw URLError(.badServerResponse)
            }
        }
        
        return (responseData, response)
    }

    private static func createBodyWithParameters(parameters: [String: Any?], filePathKey: String, fileData: Data, mimeType: String, boundary: String, fileExtension: String) -> Data {
        var body = Data()
        
        for (key, value) in parameters.filter({$1 != nil}) {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value!)\r\n")
        }
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"file\(boundary)\(fileExtension)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.appendString("\r\n")
        
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
    
    public static func delete(endPoint: String) async throws -> (Data, URLResponse) {
        let url = Foundation.URL(string: "\(URL)/\(endPoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
            print("HTTP Headers: \(httpResponse.allHeaderFields)")
            
            switch httpResponse.statusCode {
            case 200...299:
                return (responseData, response)
            case 400:
                throw URLError(.badURL)
            case 401:
                throw URLError(.userAuthenticationRequired)
            case 500:
                throw URLError(.cannotConnectToHost)
            default:
                throw URLError(.unknown)
            }
        }
        
        throw URLError(.badServerResponse)
    }
    
    public static func patch(endPoint: String) async throws -> (Data, URLResponse) {
        guard let url = Foundation.URL(string: "\(URL)/\(endPoint)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "PATCH"
        
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
            print("HTTP Headers: \(httpResponse.allHeaderFields)")
            
            switch httpResponse.statusCode {
            case 200...299:
                return (responseData, response)
            case 400:
                throw URLError(.badURL)
            case 401:
                throw URLError(.userAuthenticationRequired)
            case 500:
                throw URLError(.cannotConnectToHost)
            default:
                throw URLError(.unknown)
            }
        }
        
        throw URLError(.badServerResponse)
    }

}

extension Data {
    mutating func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}

extension Dictionary where Key == String, Value == Any {
    func percentEncoded() -> Data? {
        let queryString = map { key, value -> String in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return "\(escapedKey)=\(escapedValue)"
        }
        .joined(separator: "&")
        
        return queryString.data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
