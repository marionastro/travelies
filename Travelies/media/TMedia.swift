//
//  TMedia.swift
//  mockup
//
//  Created by Studente on 20/08/24.
//

import Foundation

class TMedia : Equatable {
    enum TMediaType {
        case image(TImage)
        case video(TVideo)
    }
    
    enum TMediaOrigin {
        case server
        case camera
        case library
    }
    
    let type: TMediaType
    let origin: TMediaOrigin
    
    func getMetadata() async throws -> TMetadata {
        switch type {
        case .image(let image):
            return try await image.getMetadata()
        case .video(let video):
            return try await video.getMetadata()
        }
    }
    
    var data: Data {
        switch type {
        case .image(let image):
            return image.data
        case .video(let video):
            return video.data
        }
    }
    
    var rawType: Int {
        switch type {
        case .image(_):
            return TImage.rawType
        case .video(_):
            return TVideo.rawType
        }
    }
    
    init(image: TImage, origin: TMediaOrigin) {
        self.type = .image(image)
        self.origin = origin
    }
    
    init(video: TVideo, origin: TMediaOrigin) {
        self.type = .video(video)
        self.origin = origin
    }
    
    static func == (lhs: TMedia, rhs: TMedia) -> Bool {
        lhs.data == rhs.data
    }
}
