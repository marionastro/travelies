//
//  TImage.swift
//  mockup
//
//  Created by Studente on 20/08/24.
//

import Foundation
import UIKit
import ImageIO
import CoreLocation

public struct TImage {
    private let url: URL?    
    let data: Data
    let uiImage: UIImage
    
    static let rawType: Int = 1
    
    public init(withData data: Data) throws {
        self.url = nil
        self.data = data
        
        guard let uiImage = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        self.uiImage = uiImage
    }
    
    public init(withURL url: URL) throws {
        self.url = url

        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data)
        else {
            throw URLError(.cannotDecodeContentData)
        }
        
        self.data = data
        self.uiImage = uiImage
    }
    
    func getMetadata() async throws -> TMetadata {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var time: String? = nil
        var lat: Double? = nil
        var lon: Double? = nil
        
        if let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
            if let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
               let exifData = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any] {

                // Ottenere la data di scatto
                if let dateString = exifData[kCGImagePropertyExifDateTimeOriginal as String] as? String,
                   let captureDate = inputFormatter.date(from: dateString) {
                    time = outputFormatter.string(from: captureDate)
                }

                // Ottenere la posizione (latitudine e longitudine)                
                if let gpsData = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
                    if let latitude = gpsData[kCGImagePropertyGPSLatitude as String] as? Double,
                       let latitudeRef = gpsData[kCGImagePropertyGPSLatitudeRef as String] as? String,
                       let longitude = gpsData[kCGImagePropertyGPSLongitude as String] as? Double,
                       let longitudeRef = gpsData[kCGImagePropertyGPSLongitudeRef as String] as? String {

                        lat = (latitudeRef == "N") ? latitude : -latitude
                        lon = (longitudeRef == "E") ? longitude : -longitude
                    }
                }

                return TMetadata(time: time, lat: lat, lon: lon)
            }
        }
        
        return TMetadata(time: nil, lat: nil, lon: nil)
    }
}
