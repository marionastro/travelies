//
//  UserProfile.swift
//  mockup
//
//  Created by Studente on 25/07/24.
//

import Foundation
import SwiftUI

struct UserProfile : View {
    @EnvironmentObject var auth: AuthenticationService
    
    @StateObject var userDataModel = UserDataModel.shared
    @StateObject var travelDataModel = TravelDataModel.shared
    @EnvironmentObject var forceRefresh: ForceRefresh
    @State private var isVisible = false 
    
    @State private var tripsCount: Int = 0
    @State private var friends: [User] = []
    
    @State private var showAlert = false
    @State private var loadingInvitation = false
    
    @StateObject var alertDataHandler = AlertDataHandler.shared
    
    func fetchInvitation() async {
        do {
            let userId = userDataModel.getCurrentUser().id
            let (data, _) = try await Rest.get(endPoint: "friend?userId=\(userId)")
            
            if let invitationCode = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") {
                let externalLink = "http://149.202.38.175/f/\(invitationCode)"
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
           let rootViewController = windowScene.windows.first?.rootViewController {
            
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
        
    var body : some View {
        NavigationStack {
            VStack {
                // Top Bar
                HStack {
                    Spacer()
                    Button(action: {
                        //showAlert = true
                        alertDataHandler.showConfirmationAlert (
                            title: "Sei sicuro di voler uscire?",
                            message: nil,
                            onOk: { auth.logOut() },
                            onCancel: { alertDataHandler.hideAlert() }
                        )
                    }) {
                        Text("Esci")
                            .font(.custom("DIN Alternate", size: 18))
                            .foregroundColor(Color(.red))
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 12)
                
                VStack(spacing: 32) {
                    // User Card
                    HStack {
                        Spacer()
                        VStack(spacing: 24) {
                            UserProfilePicture(text: userDataModel.getCurrentUser().username, size: 120)
                            VStack(spacing: 6) {
                                Text(userDataModel.getCurrentUser().username)
                                    .font(.custom("DIN Alternate", size: 24))
                                    .foregroundColor(Color(UIColor.label))
                                Text("\(tripsCount) Viaggi")
                                    .font(.custom("DIN Alternate", size: 16))
                                    .foregroundColor(Color(UIColor.lightGray))
                            }
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
                                        Text("Aggiungi amici")
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
                            
                        }
                        Spacer()
                    }

                    // Friends list
                    VStack(alignment: .leading, spacing: 32) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.custom("DIN Alternate", size: 18))
                                .foregroundColor(Color(UIColor.label))
                                .opacity(0.5)
                            Text("Amici")
                                .font(.custom("DIN Alternate", size: 24))
                                .foregroundColor(Color(UIColor.label))
                                .opacity(0.5)
                        }
                        List {
                            ForEach(friends, id: \.id) { friend in
                                UserTile(user: friend, active: true)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: delete)
                        }
                        .listRowSpacing(16)
                        .contentMargins(.vertical, 0)
                        .listStyle(GroupedListStyle())
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .padding(.horizontal, 24)
            .edgesIgnoringSafeArea([.bottom])
        }
        .onAppear(){
            isVisible = true
        }
        .onDisappear(){
            isVisible = false
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
        .task {
            let user = userDataModel.getCurrentUser()
            
            tripsCount = travelDataModel.getByUserId(userId: user.id).count
            friends = user.friends ?? []
            
            if let update = try? await UserRepository.getUser(id: user.id)?.friends, update != friends {
                friends = update
            }
        }
        .onChange(of: forceRefresh.refresh) { _,newValue in
            if newValue && isVisible{ //update user travels only if this page is on screen
                //(don't update user datas if they close camera when on their friend's page)
                Task {
                    let user = userDataModel.getCurrentUser()
                    
                    if let update = try? await UserRepository.getUser(id: user.id)?.friends, update != friends {
                        friends = update
                    }
                }
            }
        }
        .onChange(of: friends) { _, newFriends in
            var user = userDataModel.getCurrentUser()
            user.friends = newFriends
            
            userDataModel.update(user, withKey: user.id)
        }
        .refreshable {
            let user = userDataModel.getCurrentUser()
            
            if let update = try? await UserRepository.getUser(id: user.id)?.friends, update != friends {
                friends = update
            }
        }
    }
    
    func removeFriend(id: Int) {
        Task {
            do {
                try await UserRepository.deleteFriend(fromId: UserDataModel.shared.getCurrentUser().id, toId: id)
            } catch {
                print("Failed to delete travel: \(error)")
            }
        }
    }

    func delete(at offsets: IndexSet) {
        if let index = offsets.first {
            let friend = friends[index]
            removeFriend(id: friend.id)
            friends.remove(atOffsets: offsets)
        }
    }
}
