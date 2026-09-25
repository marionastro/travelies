//
//  TMetadata.swift
//  mockup
//
//  Created by Studente on 21/08/24.
//

import Foundation

struct TMetadata {
    let time: String
    var lat: Double?
    var lon: Double?
    
    init(time: String?, lat: Double?, lon: Double?) {
        if let time = time {
            self.time = time
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            self.time = dateFormatter.string(from: Date())
        }
        
        self.lat = lat
        self.lon = lon
    }
}
