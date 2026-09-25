import SwiftUI
import CoreLocation
import AVKit
import Photos

struct TripPost: View {
    @Environment(\.presentationMode) var presentation
    @State private var media: TMedia?
    @State private var addressString: String? = nil
    
    @State private var dragOffset = CGSize.zero
    @State private var currentPostOffset = CGSize.zero
    
    @State var data: Post
    
    var dataArray : [Post] = []
    @State private var dataIndex : Int  //State to allow update in dragGesture
    
    @StateObject var alertDataHandler = AlertDataHandler.shared
    
    // INIT () -----------
    
    init(dataArray: [Post], data: Post) {
        self.data = data
                
        //check if data is in array and calculate its index in it
        if let i = dataArray.sorted(by: >).firstIndex(of: data) {
            self.dataArray = dataArray.sorted(by: >)
            self.dataIndex = i
        } else {
            self.dataArray = [data]
            self.dataIndex = 0
        }
    }
    
    init(dataArray: [Post]) {
        self.dataArray = dataArray.sorted(by: >)
        self.data = dataArray[0]
        self.dataIndex = 0
    }
    
    init(data: Post) {
        self.data = data
        self.dataArray = [data]
        self.dataIndex = 0
    }
    
    //-------------------
    
    func updateCurrPost() async {
        data = dataArray[dataIndex]
        
        await fetchAddress(data: dataArray[dataIndex])
        do {
            media = try await MediaDataModel.shared.fetch(key: dataArray[dataIndex])
        } catch {
            print(error)
        }
    }
    
    func hasLocation() -> Bool {
        dataArray[dataIndex].lat != nil && dataArray[dataIndex].lon != nil
    }

    func fetchAddress(data: Post) async {
        guard let lat = data.lat, let lon = data.lon else {
            self.addressString = nil
            return
        }
            
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: lon)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                self.addressString = nil
                print("Nessun risultato trovato")
                return
            }
            
            var addressString: String = ""
            
            if let name = placemark.name {
                addressString += name
            }
            
            if let locality = placemark.locality {
                addressString += ", \(locality)"
            }

            if let country = placemark.country {
                addressString += ", \(country)"
            }
            
            self.addressString = addressString
            
        } catch {
            print("Errore nella geocodifica inversa: \(error.localizedDescription)")
            self.addressString = nil
        }
    }
    
    func openMaps() {
        guard let lat = dataArray[dataIndex].lat, let lon = dataArray[dataIndex].lon else {
            return
        }

        let urlString = "maps://?q=\(lat),\(lon)"
                
        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("L'app Mappe non è disponibile.")
            }
        }
    }
    

    func saveMediaToGallery() {
        guard let media = media else { return }

        switch media.type {
        case .image(let image):
            UIImageWriteToSavedPhotosAlbum(image.uiImage, nil, nil, nil)
            alertDataHandler.showInfoAlert(
                title: "Evvai!",
                message: "Immagine salvata nella libreria.",
                onOk: {}
            )
            
        case .video(let video):
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
            
            do {
                try video.data.write(to: tempFileURL, options: .atomic)
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        PHPhotoLibrary.shared().performChanges({
                            let creationRequest = PHAssetCreationRequest.forAsset()
                            creationRequest.addResource(with: .video, fileURL: tempFileURL, options: nil)
                            
                        }) { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    alertDataHandler.showInfoAlert(
                                        title: "Evvai!",
                                        message: "Video salvato nella libreria.",
                                        onOk: {}
                                    )
                                } else {
                                    alertDataHandler.showInfoAlert(
                                        title: "Errore",
                                        message: "Impossibile salvare il video nella galleria. Prova a riavviare l'app.",
                                        onOk: {}
                                    )
                                }
                            }
                            
                            try? FileManager.default.removeItem(at: tempFileURL)
                        }
                    } else {
                        DispatchQueue.main.async {
                            alertDataHandler.showInfoAlert(
                                title: "Errore",
                                message: "L'app non ha l'autorizzazione per accedere alla libreria.",
                                onOk: {}
                            )
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    alertDataHandler.showInfoAlert(
                        title: "Errore",
                        message: "Impossibile salvare il video nella galleria. Prova a riavviare l'app.",
                        onOk: {}
                    )
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 18) {
                Button(action: { self.presentation.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color(UIColor.label))
                        .font(.system(size: 24, weight: .semibold))
                }
                Spacer()
                Button(action: {
                    DispatchQueue.main.async {
                         saveMediaToGallery()
                    }
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(Color(UIColor.label))
                        .font(.system(size: 24, weight: .semibold))
                }
                
                if data.user.id == UserDataModel.shared.getCurrentUser().id {
                    Button(action: {
                        alertDataHandler.showConfirmationAlert(
                            title: "Sei sicuro?",
                            message: "Sei sicuro di voler eliminare questo post?",
                            onOk: { deletePost() },
                            onCancel: {}
                        )
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 24, weight: .semibold))
                    }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 12)
            Spacer()
            VStack(spacing: 24) {
                    if let media = media {
                        switch (media.type) {
                        case .image(let image):
                            Image(uiImage: image.uiImage)
                                .resizable()
                                .aspectRatio(3/4, contentMode: .fit)
                                .cornerRadius(24)
                        case .video(let video):
                            VideoPlayer(player: AVPlayer(playerItem: AVPlayerItem(asset: video.avAsset)))
                                .aspectRatio(3/4, contentMode: .fit)
                                .cornerRadius(24)
                        }
                    } else {
                        Rectangle()
                            .clipped()
                            .aspectRatio(3/4, contentMode: .fit)
                            .cornerRadius(24)
                            .foregroundColor(Color("ThemeGray"))
                            .task {
                                do {
                                    media = try await MediaDataModel.shared.fetch(key: dataArray[dataIndex])
                                } catch {
                                    print(error)
                                }
                            }
                    }
                
                VStack(spacing: 4) {
                    HStack {
                        Text("\(dataArray[dataIndex].user.username)")
                            .font(.custom("DIN Alternate", size: 18))
                            .foregroundColor(Color(UIColor.label))
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundColor(Color(UIColor.label))
                        Text("\(dataArray[dataIndex].getDateTimeObject().toMonthDateString())")
                            .font(.custom("DIN Alternate", size: 18))
                            .foregroundColor(Color(UIColor.label))
                    }
                    
                    if let addressString = addressString {
                        Button(action: { openMaps() }) {
                            Text(addressString)
                                .font(.custom("DIN Alternate", size: 18))
                                .foregroundColor(Color(UIColor.lightGray))
                                .underline()
                        }
                    } else {
                        if hasLocation() {
                            ProgressView()
                                .foregroundColor(Color(UIColor.lightGray))
                                .task {
                                    await fetchAddress(data: dataArray[dataIndex])
                                }
                        } else {
                            Text("Posizione sconosciuta")
                                .font(.custom("DIN Alternate", size: 18))
                                .foregroundColor(Color(UIColor.lightGray))
                        }
                    }
                }
            }
            // VERTICAL SWIPE
            .offset(y: currentPostOffset.height + dragOffset.height)
            .animation(.easeInOut, value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        if value.translation.height < -50 {
                            
                            // Swipe a sinistra
                            if dataIndex < dataArray.count - 1  {
                                
                                dataIndex += 1
                                Task{
                                    await updateCurrPost()
                                }
                            }
                        } else if value.translation.height > 50 {
                            // Swipe a destra
                            if dataIndex > 0 {
                                
                                dataIndex -= 1
                                Task{
                                    await updateCurrPost()
                                }
                            }
                        }
                        // Reset shifting for the next drag
                        withAnimation {
                            currentPostOffset = dragOffset
                            dragOffset = .zero
                        }
                        
                        // Reset offset after animation
                        withAnimation(.spring()) {
                            currentPostOffset = .zero
                        }
                    }
                
                )
            .onDisappear {
                media = nil
                addressString = nil
                dataIndex = 0
            }
            .padding(.top, 16)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom) //altrimenti navigator copre l'indirizzo
        .edgesIgnoringSafeArea([.bottom])
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
    }
    
    func deletePost() {
        Task {
            do {
                try await PostRepository.deletePost(post: data, currentUser: UserDataModel.shared.getCurrentUser())
                
                alertDataHandler.showInfoAlert(
                    title: "Il post è stato rimosso.",
                    message: nil,
                    onOk: { self.presentation.wrappedValue.dismiss() }
                )
            } catch {
                alertDataHandler.showInfoAlert(
                    title: "Errore",
                    message: error.localizedDescription,
                    onOk: {}
                )
            }
        }
    }
}
