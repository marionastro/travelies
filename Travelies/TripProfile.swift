//
//  TripProfile.swift
//  mockup
//
//  Created by Studente on 07/07/24.
//

import SwiftUI
import AVKit
import MapKit
import Combine


struct TripProfile: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var forceRefresh: ForceRefresh //tells if the camera sheet has been closed
    @State private var isVisible = false //tells if this page is currently on screen
    
    @StateObject var travelDataModel = TravelDataModel.shared
    @StateObject private var markerNavigationStatePost = MarkerNavigationStatePost()
    
    //default camera value
    @State var cameraPosition = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
        span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
    )
    
    @State private var postOpened = false
    
    @State private var showMembers = false
    @State private var loadingInvitation = false
        
    @State var data: Travel?
    @State var posts: [Post] = []
    @State var members: [User] = []
    @State var membersCount: Int = 0
    
    @State var loadingPrivacy: Bool = false
    @State var privacy: Int = 1

    let travelId: Int?
    
    @StateObject var alertDataHandler = AlertDataHandler.shared
    
    var body: some View {
        VStack {
            // Top Bar
            HStack {
                Button(action: {
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color(UIColor.label))
                        .font(.system(size: 24, weight: .semibold))
                }
                Spacer()
                HStack(spacing: 18) {
                    Button(action: { showMembers = data != nil }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color(UIColor.label))
                            .font(.system(size: 24, weight: .semibold))
                    }
                    .sheet(isPresented: $showMembers) {
                        VStack(alignment: .leading, spacing: 32) {
                            HStack {
                                Spacer()
                                VStack(spacing: 24) {
                                    VStack(spacing: 8) {
                                        Text("\(membersCount) Partecipanti")
                                            .font(.custom("DIN Alternate", size: 24))
                                            .foregroundColor(Color(UIColor.label))
                                        Text("oltre \(data?.creator.username ?? "")")
                                            .font(.custom("DIN Alternate", size: 18))
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                    }
                                    
                                    if data?.creator == UserDataModel.shared.getCurrentUser() {
                                        HStack {
                                            Button(action: {
                                                loadingInvitation = true
                                                
                                                Task {
                                                    await fetchInvitation()
                                                }
                                            }) {
                                                ZStack {
                                                    if loadingInvitation {
                                                        ProgressView()
                                                            .opacity(1)
                                                            .foregroundColor(.white)
                                                            .zIndex(999)
                                                    }
                                                    
                                                    HStack {
                                                        Image(systemName: "link")
                                                            .font(.custom("DIN Alternate", size: 18))
                                                            .foregroundColor(.white)
                                                            .opacity(0.5)
                                                        Text("Aggiungi partecipanti")
                                                            .font(.custom("DIN Alternate", size: 18))
                                                            .foregroundColor(.white)
                                                    }
                                                    .opacity(loadingInvitation ? 0 : 1)
                                                }
                                                .padding([.top, .bottom], 16)
                                                .padding([.trailing, .leading], 34)
                                            }
                                            .background(Color("CameraYellow"))
                                            .cornerRadius(18)
                                            Button(action: {
                                                loadingPrivacy = true
                                                
                                                Task {
                                                    await handlePrivacy()
                                                }
                                            }) {
                                                ZStack {
                                                    Image(systemName: privacy == 1 ? "lock.open.fill" : "lock.fill")
                                                        .font(.custom("DIN Alternate", size: 18))
                                                        .foregroundColor(.white)
                                                        .opacity(loadingPrivacy ? 0 : 1)
                                                    
                                                    if loadingPrivacy {
                                                        ProgressView()
                                                            .opacity(1)
                                                            .foregroundColor(.white)
                                                            .zIndex(999)
                                                    }
                                                }
                                                .padding(16)
                                            }
                                            .background(privacy == 1 ? .green : .red)
                                            .cornerRadius(18)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(.top)
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .font(.custom("DIN Alternate", size: 18))
                                    .foregroundColor(Color(UIColor.label))
                                    .opacity(0.5)
                                Text("Partecipanti")
                                    .font(.custom("DIN Alternate", size: 24))
                                    .foregroundColor(Color(UIColor.label))
                                    .opacity(0.5)
                            }
                            List {
                                if data?.creator == UserDataModel.shared.getCurrentUser() {
                                    ForEach(members, id: \.id) { user in
                                        UserTile(user: user, active: false)
                                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                    }
                                    .onDelete(perform: deleteMember)
                                } else {
                                    ForEach(members, id: \.id) { user in
                                        UserTile(user: user, active: false)
                                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                    }
                                }
                            }
                            .listRowSpacing(16)
                            .contentMargins(.vertical, 0)
                            .listStyle(GroupedListStyle())
                            .scrollContentBackground(.hidden)
                        }
                        .padding(18)
                        .edgesIgnoringSafeArea([.bottom])
                        .presentationDetents([.large], selection: .constant(PresentationDetent.large))
                        .presentationDragIndicator(.visible)
                        .task {
                            // Code inside here is already running in an async context
                            do {
                                try await updateTravel()
                            } catch {
                                print(error)
                            }
                        }
                        .refreshable {
                            // Code inside here is already running in an async context
                            do {
                                try await updateTravel()
                            } catch {
                                print(error)
                            }
                        }
                    }
                    
                    RemoveButton(forUserId: UserDataModel.shared.getCurrentUser().id, travel: data)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 12)
            
            ScrollViewReader { scrollOffset in
                ScrollView {
                    VStack {
                        // Mappa e Icona
                        ZStack(alignment: .bottom) {
                            PostMap(cameraPosition: $cameraPosition, markerNavigationStatePost: markerNavigationStatePost, posts: posts.filter { $0.lat != nil && $0.lon != nil })
                                .cornerRadius(24)
                                .frame(minHeight: 200, maxHeight: 200)
                                .id("top")
                            ZStack {
                                Circle()
                                    .frame(width: 85, height: 85)
                                    .foregroundColor(Color("ThemeGray"))
                                Circle()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(Color(UIColor.systemBackground))
                                Image("location.dot.fill")
                                    .resizable()
                                    .frame(width: 27, height: 34)
                            }
                            .offset(y: 40)
                            .onTapGesture {
                                updateCameraPosition()
                            }
                        }
                        .padding([.bottom], 42)
                        
                        // Titolo e Data
                        VStack(spacing: 6) {
                            if let data = data {
                                Text(data.name)
                                    .font(.custom("DIN Alternate", size: 24))
                                    .textCase(.uppercase)
                                    .foregroundColor(Color(UIColor.label))
                                
                                if !posts.isEmpty {
                                    let startDateString = data.getStartAndEndDateTimes()?.0.toShortMonthDateString()
                                    let endDateString = data.getStartAndEndDateTimes()?.1.toShortMonthDateString()
                                    
                                    Text("\(startDateString ?? "") - \(endDateString ?? "")")
                                        .font(.custom("DIN Alternate", size: 14))
                                        .foregroundColor(Color(UIColor.lightGray))
                                } else {
                                    Text("Ancora nessun post")
                                        .font(.custom("DIN Alternate", size: 14))
                                        .foregroundColor(Color(UIColor.lightGray))
                                }
                                
                            }
                        }
                        //open image relateed to picture
                        .navigationDestination(isPresented: .constant(markerNavigationStatePost.isSelected())) {
                            if let post = markerNavigationStatePost.selectedItem {
                                TripPost(dataArray: post)
                                    .onAppear(){
                                        postOpened = true
                                    }
                                    .onDisappear(){
                                        postOpened = false //reset flag
                                    }
                            }
                        }
                        .padding([.bottom], 14)
                        
                        // Posts
                        if !posts.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(posts.count) Post")
                                    .font(.custom("DIN Alternate", size: 14))
                                    .foregroundColor(Color(UIColor.lightGray))
                                    .padding([.bottom], 6)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 2), count: 3), spacing: 2) {
                                    ForEach(posts.sorted(by: >)) { post in
                                        NavigationLink(destination: TripPost(dataArray: posts, data: post)
                                            .onAppear(){
                                                postOpened = true
                                            }
                                            .onDisappear(){
                                                postOpened = false //reset flag
                                            }
                                        ) {
                                            if post.dataType == TVideo.rawType {
                                                VideoThumbnailView(post: post)
                                            } else if post.dataType == TImage.rawType {
                                                AsyncImageView(post: post)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding([.bottom], 14)
                }
                .onAppear(){
                    if !postOpened { //do not reset scroll if coming from post
                        scrollOffset.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
        .onDisappear(){
            //going to post: post appear (postOpened <- true) --> profile disappear
            //coming back: profile appear --> post disappear (postOpened <- false)
            
            if !postOpened { //don't update camera when coming back from post
                updateCameraPosition() //when opening same trip twice in a row, camera need to be reset
            }
        }
        .edgesIgnoringSafeArea([.bottom])
        .padding([.trailing, .leading], 24)
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
        .task {
            // Code inside here is already running in an async context
            do {
                try await updateTravel()
            } catch {
                print(error)
            }
        }
        .onChange(of: forceRefresh.refresh) { _,newValue in
            if newValue && isVisible { //update user travels only if this page is on screen
                                       //(don't update user datas if they close camera when on their friend's page)
                Task {
                    do {
                        try await updateTravel()
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .onChange(of: data) { _,newData in
            if let newData = newData {
                TravelDataModel.shared.update(newData, withKey: newData.id)
            }
        }
        .refreshable {
            // Code inside here is already running in an async context
            do {
                try await updateTravel()
            } catch {
                print(error)
            }
        }
        .onAppear(){
            isVisible = true
        }
        .onDisappear(){
            isVisible = false
        }
    }
    
    private func RemoveButton(forUserId userId: Int, travel: Travel?) -> some View {
        if let user = UserDataModel.shared.get(key: userId) {
            if travel?.creator == user {
                return AnyView(
                    Button(action: {
                        alertDataHandler.showConfirmationAlert(
                            title: "Sei sicuro?",
                            message: "Sei sicuro di voler eliminare questo viaggio e tutti i suoi post?",
                            onOk: { deleteTrip() },
                            onCancel: {}
                        )
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(Color(.red))
                            .font(.system(size: 24, weight: .semibold))
                    }
                )
            } else if ((travel?.isMember(user: user)) != nil) {
                return AnyView(
                    Button(action: {
                        alertDataHandler.showConfirmationAlert(
                            title: "Sei sicuro?",
                            message: "Sei sicuro di uscire da questo viaggio?",
                            onOk: { deleteTrip() },
                            onCancel: {}
                        )
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(Color(.red))
                            .font(.system(size: 24, weight: .semibold))
                    }
                )
            }
        }
        
        return AnyView(EmptyView())
    }

    private func updateTravel() async throws {
        markerNavigationStatePost.reset()
        
        guard let travelId = travelId else {
            // TODO gestire l'errore
            return
        }
        
        data = try await travelDataModel.fetch(key: travelId)
        
        if let data = data {
            posts = data.posts ?? []
            privacy = data.privacy
            members = data.members ?? []
            membersCount = members.count
        }
        
        if let update = try? await TravelRepository.getTravel(id: travelId), update != data {            
            withAnimation {
                data = update
                posts = update.posts ?? []
                members = update.members ?? []
                privacy = update.privacy
                membersCount = members.count
            }        
        }
        
        //update camera when new travel is loaded
        if data != nil && !postOpened { //avoid updating camera when setting data to nil and when coming back from post
            updateCameraPosition()
        }
    }
    
    func handlePrivacy() async {
        do {
            let userId = UserDataModel.shared.getCurrentUser().id
            let newPrivacy = privacy ^ 1
                    
            if var data = data {
                try await TravelRepository.editTravel(tripId: data.id, userId: userId, privacy: newPrivacy)
                
                data.privacy = newPrivacy
                
                TravelDataModel.shared.update(data, withKey: data.id)
                
                self.data = data
            
                loadingPrivacy = false
                
                withAnimation {
                    privacy = newPrivacy
                }

            }
        } catch {
            print("Failed to modyfy privacy: \(error)")
        }
        
    }
    
    func fetchInvitation() async {
        do {
            let userId = UserDataModel.shared.getCurrentUser().id
            let (data, _) = try await Rest.get(endPoint: "join?tripId=\(self.travelId!)&userId=\(userId)")
            
            if let invitationCode = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") {
                let externalLink = "http://149.202.38.175/j/\(invitationCode)"
                shareInvitationLink(invitationLink: externalLink)
            } else {
                print("Failed to decode invitation data")
            }
        } catch {
            print("Error fetching invitation: \(error.localizedDescription)")
        }
    }
    
    func shareInvitationLink(invitationLink: String) {
        let activityViewController = UIActivityViewController(activityItems: [invitationLink], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController?.presentedViewController {
            
            rootViewController.definesPresentationContext = true
            
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                                      y: rootViewController.view.bounds.midY,
                                                      width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            loadingInvitation = false
            
            DispatchQueue.main.async {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    func removePartecipante(userId: Int) {
        Task {
            do {
                if let data = data {
                    try await TravelRepository.deletePartecipante(tripId: data.id, creatorId: UserDataModel.shared.getCurrentUser().id, userId: userId)
                }
            } catch {
                print("Failed to delete travel: \(error)")
            }
        }
    }
    
    func deleteMember(at offsets: IndexSet) {
        if let index = offsets.first {
            let member = members[index]
            removePartecipante(userId: member.id)
            members.remove(atOffsets: offsets)
            membersCount -= 1
        }
    }
    
    func deleteTrip() {
        Task {
            do {
                try await TravelRepository.deleteTravel(
                    travelId: data!.id, userId: UserDataModel.shared.getCurrentUser().id)
                self.presentation.wrappedValue.dismiss()
            } catch {
                print("Failed to delete travel: \(error)")
                alertDataHandler.showInfoAlert(title: "Errore", message: "Errore nella rimozione del viaggio.", onOk: {})
            }
        }
    }
    
    private func updateCameraPosition() {
        let center =  data?.getCenter()
        
        let bounds = Post.bounds(for: data?.posts ?? [])
        
        let postMaxLat = bounds.maxLat
        let postMinLat = bounds.minLat
        let postMaxLon = bounds.maxLon
        let postMinLon = bounds.minLon
                
        //for travel without posts/with post with no coordinates, use high span
        //prevent too little/big span value
        let spanLat = (center != nil)  ? max(10, min((postMaxLat - postMinLat) * 2, 130)) : 130
        let spanLon = (center != nil)  ? max(10, min((postMaxLon - postMinLon) * 2, 130)) : 130
        withAnimation{
            cameraPosition = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: (center?.0 ?? 0.0) + Double.random(in: 0.00001...0.001), longitude: (center?.1 ?? 0.0)),
                span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
            )
        }
        
        print("camera updated")
    }
}
