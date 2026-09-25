//
//  MediaDataModel.swift
//  mockup
//
//  Created by Studente on 19/08/24.
//

import Foundation
import UIKit

public class MediaDataModel : DataModel {
    typealias K = Post
    typealias T = TMedia
    
    static let shared = MediaDataModel()
    
    private var fetching: TSet<Post> = TSet()
    
    @Published private var byId: TCache<Post, TMedia> = TCache()
    
    func update(_ data: TMedia?, withKey key: Post) {
        guard let media = data else {
            return
        }
        
        let _ = byId.set(media, forKey: key)
    }
    
    func reset(key: Post) {
        let _ = byId.set(nil, forKey: key)
    }
    
    func resetAll() {
        byId = TCache()
    }
    
    func get(key: Post) -> TMedia? {
        byId.get(forKey: key)
    }
    
    func getAll() -> [TMedia] {
        byId.values
    }
    
    func fetch(key: Post) async throws -> TMedia? {
        if let media = byId.get(forKey: key) {
            return media
        }
        
        guard fetching.insert(key) else {
            return nil
        }
        
        let url: URL? = URL(string: "\(Rest.URL)/\(key.dataPath)")
        var media: TMedia? = nil
        
        if let url = url {
            switch (key.dataType) {
            case TImage.rawType:
                let image = try TImage(withURL: url)
                media = TMedia(image: image, origin: .server)
            case TVideo.rawType:
                let video = try TVideo(withURL: url)
                media = TMedia(video: video, origin: .server)
            default:
                return nil
            }
        }
        
        let _ = byId.set(media, forKey: key)
        fetching.remove(key)
        return media
    }
}
