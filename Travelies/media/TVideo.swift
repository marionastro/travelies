//
//  TVideo.swift
//  mockup
//
//  Created by Studente on 20/08/24.
//

import Foundation
import AVFoundation

public struct TVideo {
    let url: URL
    let data: Data
    let avAsset: AVAsset
    
    static let rawType: Int = 2
    
    public init(withURL url: URL) throws {
        self.url = url
        
        guard let data = try? Data(contentsOf: url) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        self.data = data
        self.avAsset = AVAsset(url: url)
    }

    func getMetadata() async throws -> TMetadata {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var time: String?
        var lat: Double?
        var lon: Double?
        
        for format in try await avAsset.load(.availableMetadataFormats) {
            let metadata = try await avAsset.loadMetadata(for: format)
            for item in metadata {
                // Gestione della data di creazione
                if item.commonKey?.rawValue == "creationDate" {
                    let value = try await item.load(.value)
                    if let creationDate = value as? String {
                        let isoFormatter = ISO8601DateFormatter()
                        if let date = isoFormatter.date(from: creationDate) {
                            time = dateFormatter.string(from: date)
                        }
                    }
                }

                // Gestione della posizione (latitudine e longitudine)
                if item.keySpace?.rawValue == AVMetadataKeySpace.quickTimeMetadata.rawValue,
                   item.key as? String == "com.apple.quicktime.location.ISO6709" {
                    let value = try await item.load(.value)
                    if let locationString = value as? String {
                        let coordinates = locationString.split(separator: "+").map { Double($0) }
                        if coordinates.count >= 2 {
                            lat = coordinates[0]
                            lon = coordinates[1]
                        }
                    }
                }
            }
        }
        
        return TMetadata(time: time, lat: lat, lon: lon)
    }
}
