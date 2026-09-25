//
//  TripCreate.swift
//  mockup
//
//  Created by Studente on 08/08/24.
//

import Foundation
import SwiftUI

struct TripCreate: View {
    @Environment(\.presentationMode) var presentation
    @StateObject var alertDataHandler = AlertDataHandler.shared
    
    @State var travelName: String = ""
    
    let user = UserDataModel.shared.getCurrentUser()
    
    var body: some View {
        VStack {
            // Top Bar
            HStack {
                Button(action: { self.presentation.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color(UIColor.label))
                        .font(.system(size: 24, weight: .semibold))
                }
                Spacer()
                Button(action: {
                    createTrip()
                }) {
                    Text("Crea")
                        .font(.custom("DIN Alternate", size: 18))
                        .foregroundColor(Color("CameraYellow"))
                }
                .opacity((travelName.count > 0 && travelName.count < 50) ? 1 : 0.5)
                .disabled(!(travelName.count > 0 && travelName.count < 50))
            }
            .padding(.top, 6)
            .padding(.bottom, 12)
            //-----
            VStack(spacing: 24) {
                Text("Come vuoi chiamare il viaggio?")
                    .multilineTextAlignment(.center)
                    .font(.custom("DIN Alternate", size: 24))
                    .foregroundColor(Color(UIColor.label))
                VStack(spacing: 12) {
                    TextField("Nome del viaggio", text: $travelName)
                        .font(.custom("DIN Alternate", size: 18))
                        .multilineTextAlignment(.leading)
                        .padding(12)
                        .foregroundColor(Color(UIColor.label))
                        .autocorrectionDisabled()
                        .overlay(Rectangle().frame(width: nil, height: 3, alignment: .bottom).foregroundColor(Color(UIColor.label)), alignment: .bottom)
                        .cornerRadius(8)
                    Text("Il nome del viaggio non può superare i 50 caratteri.")
                        .font(.custom("DIN Alternate", size: 12))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
            .padding(.top, 128)
            .padding(.horizontal, 24)
            //-----
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .edgesIgnoringSafeArea([.bottom])
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
    }
    
    func createTrip() {
        Task {
            do {
                _ = try await TravelRepository.insertTravel(data: TravelRepository.TravelPostData(name: travelName, creator: user.id, privacy: 0))
                alertDataHandler.showInfoAlert(title: "Evvai!", message: "Il viaggio è stato creato con successo.", onOk: { self.presentation.wrappedValue.dismiss() })
            } catch {
                if let error = error as? URLError, error.code == .badServerResponse {
                    alertDataHandler.showInfoAlert(title: "Impossibile creare il viaggio", message: "Hai già creato un viaggio con questo nome.", onOk: {})
                } else {
                    alertDataHandler.showInfoAlert(title: "Impossibile creare il viaggio", message: "Si è verificato un errore durante la creazione del viaggio.", onOk: {})
                }
            }
        }
    }
}
