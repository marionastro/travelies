import SwiftUI
import AVFoundation
import AVKit
import Photos
import CoreGraphics
import CoreLocation

struct Uploader: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSheet = false
    @State private var settingsDetent = PresentationDetent.medium
    
    @State private var selectedItem: Travel?
    @State private var uploading = false
    
    @State private var locationObtainer: CameraLocationObtainer? = nil
    
    @StateObject var travelDataModel = TravelDataModel.shared
    @StateObject var userDataModel = UserDataModel.shared
    
    let currentUser = UserDataModel.shared.getCurrentUser()
    
    var media: TMedia?
    
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Button(action: { showingSheet = true }) {
                HStack(spacing: 4) {
                    if let selected = selectedItem {
                        Text("Aggiungi a")
                            .font(.custom("DIN Alternate", size: 16))
                            .foregroundColor(Color(UIColor.systemGray))
                        Text("\(selected.name)")
                            .font(.custom("DIN Alternate", size: 16))
                            .foregroundColor(.white)
                    } else {
                        Text("Scegli il viaggio")
                            .font(.custom("DIN Alternate", size: 16))
                            .foregroundColor(Color(UIColor.systemGray))
                    }
                }
            }
            .opacity(uploading ? 0.25 : 1)
            .disabled(uploading)
            .sheet(isPresented: $showingSheet) {
                ZStack {
                    VStack {
                        ZStack(alignment: .center) {
                            Text("Scegli il viaggio")
                                .font(.custom("DIN Alternate", size: 18))
                                .foregroundColor(.white)
                            HStack {
                                Button(action: { showingSheet = false }) {
                                    Text("Annulla")
                                        .font(.custom("DIN Alternate", size: 18))
                                        .foregroundColor(Color(UIColor.systemGray))
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        List {
                            ForEach(travelDataModel.getByUserId(userId: currentUser.id).sorted(by: <), id: \.self) { travel in
                                MiniTile (
                                    title: travel.name, member: travel.creator != currentUser,
                                    action: {
                                        selectedItem = travel
                                        showingSheet = false
                                    },
                                    selected: travel == selectedItem
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listRowSpacing(4)
                        .contentMargins(.vertical, 0)
                        .listStyle(GroupedListStyle())
                        .scrollContentBackground(.hidden)
                    }
                    .padding(18)
                }
                .background(Color("GrayBackground"))
                .edgesIgnoringSafeArea([.bottom])
                .presentationDetents([.medium, .large], selection: $settingsDetent)
                .presentationDragIndicator(.visible)
            }

            // Content
            ZStack {
                if let media = media {
                    switch(media.type) {
                    case .image(let image):
                        Image(uiImage: image.uiImage)
                            .resizable()
                            .aspectRatio(3/4, contentMode: .fit)
                            .cornerRadius(24)
                    case .video(let video):
                        let player = AVPlayer(url: video.url)
                        VideoPlayer(player: player)
                            .ignoresSafeArea()
                            .aspectRatio(3/4, contentMode: .fit)
                            .cornerRadius(24)
                            .onAppear {
                                player.play()
                            }
                            .onDisappear {
                                player.pause()
                            }
                    }
                }
            }
            .padding(24)

            HStack(spacing: 24) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .padding([.top, .bottom], 20)
                        .padding([.trailing, .leading], 36)
                }
                .background(Color(UIColor.systemGray))
                .cornerRadius(48)
                .opacity(uploading ? 0.25 : 1)
                .disabled(uploading)

                Button(action: {
                    DispatchQueue.main.async {
                        handleUpload()
                    }
                    
                    uploading = true
                }) {
                    ZStack {
                        if uploading {
                            ProgressView()
                                .opacity(1)
                                .foregroundColor(.white)
                                .zIndex(999)
                        }
                        
                        Text("Continua")
                            .font(.custom("DIN Alternate", size: 18))
                            .foregroundColor(.white)
                            .opacity(uploading ? 0 : 1)
                    }
                    .padding([.top, .bottom], 20)
                    .padding([.trailing, .leading], 36)
                }
                .background(Color("CameraYellow"))
                .cornerRadius(48)
                .opacity(selectedItem == nil ? 0.25 : 1)
                .disabled(selectedItem == nil || uploading)
            }
            Spacer()
        }
        .background(.black)
        .edgesIgnoringSafeArea([.top, .bottom])
        .onAppear {
            locationObtainer = CameraLocationObtainer()
            requestPhotoLibraryAccess { granted in
                if !granted {
                    print("Photo library access not granted")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
    }
    
    private func handleUpload() {
        guard let selectedItem = selectedItem,
              let media = media
        else {
            return
        }
        
        Task {
            var metadata = (try? await media.getMetadata()) ?? TMetadata(time: nil, lat: nil, lon: nil)

            if media.origin == .camera {
                if let locationObtainer = locationObtainer,
                   let location = locationObtainer.lastLocation
                {
                    metadata.lat = location.coordinate.latitude
                    metadata.lon = location.coordinate.longitude
                }
            }
            
            await upload(media, to: selectedItem, with: metadata)
        }
    }
    
    private func upload(_ media: TMedia, to travel: Travel, with metadata: TMetadata) async {
        let postData = PostRepository.PostData(
            time: metadata.time,
            lat: metadata.lat,
            lon: metadata.lon,
            datatype: media.rawType,
            trip: travel.id,
            user: currentUser.id,
            data: media.data
        )
        
        do {
            let post = try await PostRepository.insertPost(data: postData)
            var mutableTravel = TravelDataModel.shared.get(key: travel.id)
            mutableTravel?.addPost(post: post)
            
            if let mutableTravel = mutableTravel {
                TravelDataModel.shared.update(mutableTravel, withKey: mutableTravel.id)
                MediaDataModel.shared.update(media, withKey: post)
            }

            print("Successfully uploaded post. Response: \(post)")
        } catch {
            print("Upload Error: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

extension Uploader {
    private func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized:
            print("Photo library access is already granted.")
            completion(true)
        case .denied, .restricted:
            print("Photo library access denied or restricted.")
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        print("Photo library access granted.")
                    } else {
                        print("Photo library access not granted.")
                    }
                    completion(status == .authorized)
                }
            }
        case .limited:
            print("Photo library access is limited.")
            completion(false)
        @unknown default:
            print("Unknown photo library authorization status.")
            completion(false)
        }
    }
}
