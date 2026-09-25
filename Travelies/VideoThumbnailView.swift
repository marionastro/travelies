//
//  VideoThumbnailView.swift
//  mockup
//
//  Created by Studente on 01/09/24.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

struct VideoThumbnailView: View {
    let post: Post
    let playSize: Double
    
    init(post: Post, playSize: Double = 36){
        self.post = post
        self.playSize = playSize
    }
    
    @State private var thumbnail: UIImage? = nil
    
    var body: some View {
        return ZStack {
            if let thumbnail = thumbnail {
                ZStack {
                    GeometryReader { proxy in
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width)
                    }
                }
                .clipped()
                .aspectRatio(1, contentMode: .fit)
            } else {
                Rectangle()
                    .clipped()
                    .aspectRatio(1, contentMode: .fill)
                    .foregroundColor(Color("ThemeGray"))
                    .task {
                        do {
                            try await loadThumbnail()
                        } catch {
                            print(error)
                        }
                    }
            }
            
            Image(systemName: "play.fill")
                .foregroundColor(.white)
                .font(.system(size: playSize, weight: .semibold))
                .shadow(
                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.25),
                    radius: playSize/3.6,
                    x: 0,
                    y: 0
                )
        }
    }
    
    func loadThumbnail() async throws {
        let media = try await MediaDataModel.shared.fetch(key: post)
        
        if let media = media, case let .video(video) = media.type {
            let imageGenerator = AVAssetImageGenerator(asset: video.avAsset)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 1, preferredTimescale: 60)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                thumbnail = UIImage(cgImage: cgImage)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
