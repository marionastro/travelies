//
//  MiniTile.swift
//  mockup
//
//  Created by Studente on 24/07/24.
//

import Foundation
import SwiftUI

struct MiniTile : View {
    let title    : String
    let member: Bool
    let action   : () -> Void
    let selected : Bool
    
    var body : some View {
        HStack {
            Button(action: action) {
                HStack(alignment: .center, spacing: 8) {
                    Text(title)
                        .font(.custom("DIN Alternate", size: 24))
                        .textCase(.uppercase)
                        .foregroundColor(selected ? .black : .white)
                    
                    if member {
                        Image(systemName: "person.2.fill")
                            .font(.custom("DIN Alternate", size: 12))
                            .foregroundColor(selected ? .black : .white)
                            .opacity(0.85)
                    }
                }
                .padding([.leading, .trailing], 24)
                .padding([.top, .bottom], 20)
            }
            Spacer()
        }
        .background(Color(selected ? "LightGray" : "DarkGray"))
        .cornerRadius(18)
        .edgesIgnoringSafeArea([.bottom])
        .padding(4)
    }
}
