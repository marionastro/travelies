//
//  UserTile.swift
//  mockup
//
//  Created by Studente on 25/07/24.
//

import Foundation
import SwiftUI

struct UserTile: View {
    let user: User
    @State private var showFriend = false
    
    @EnvironmentObject var forceRefresh: ForceRefresh
    
    let active: Bool
    
    var body: some View {
        if active {
            NavigationLink(destination: ContentView(user: user, friendPage: true).environmentObject(forceRefresh)){
                Content()
            }
        } else {
            Content()
        }
    }
    
    func Content() -> some View {
        HStack(spacing: 16) {
            UserProfilePicture(text: user.username, size: 60)
            Text(user.username)
                .font(.custom("DIN Alternate", size: 18))
                .foregroundColor(Color(UIColor.label))
        }
    }
}
