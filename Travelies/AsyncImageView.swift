//
//  AsyncImageView.swift
//  mockup
//
//  Created by Studente on 01/09/24.
//

import Foundation
import SwiftUI

struct AsyncImageView: View {
    let post: Post
    @State private var uiImage: UIImage? = nil
    
    var body: some View {
        return ZStack {
            if let uiImage = uiImage {
                ZStack {
                    GeometryReader { proxy in
                        Image(uiImage: uiImage)
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
                            let media = try await MediaDataModel.shared.fetch(key: post)
                            
                            if let media = media, case let .image(image) = media.type {
                                uiImage = image.uiImage
                            }
                        } catch {
                            print(error)
                        }
                    }
            }
        }
    }
}
