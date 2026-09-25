//
//  BasicTile.swift
//  mockup
//
//  Created by Studente on 24/07/24.
//

import Foundation
import SwiftUI

struct TravelTile : View {
    @EnvironmentObject var forceRefresh: ForceRefresh //tells if the camera sheet has been closed
    let data: Travel
    let member: Bool
    let action : () -> Void
    
    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .frame(width: 75, height: 75)
                    .foregroundColor(Color("ThemeLightGray"))
                Circle()
                    .frame(width: 70, height: 70)
                    .foregroundColor(Color(UIColor.systemBackground))
                Image("location.dot.fill")
                    .resizable()
                    .frame(width: 22, height: 29)
                    
            }
            .simultaneousGesture(TapGesture().onEnded {
                action()
            })
            
            NavigationLink(destination: TripProfile(travelId: data.id).environmentObject(forceRefresh)) {
                HStack(alignment: .center, spacing: 8) {
                    Text(data.name)
                        .font(.custom("DIN Alternate", size: 24))
                        .textCase(.uppercase)
                        .foregroundColor(Color(UIColor.label))
                    
                    if member {
                        Image(systemName: "person.2.fill")
                            .font(.custom("DIN Alternate", size: 12))
                            .foregroundColor(Color(UIColor.label))
                            .opacity(0.85)
                    }
                }
            }
            Spacer()
        }
        .padding([.leading, .trailing], 18)
        .padding([.top, .bottom], 14)
        .background(Color("ThemeLightGray"))
        .cornerRadius(24)
        .edgesIgnoringSafeArea([.bottom])
    }
}
