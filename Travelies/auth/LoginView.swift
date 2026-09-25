//
//  LoginView.swift
//  mockup
//
//  Created by Studente on 25/07/24.
//

import Foundation
import SwiftUI

struct LoginPostResponse : Decodable {
    let id: Int
    let sessionKey: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionKey = "session_key"
    }
}

struct LoginView : View {
    @EnvironmentObject var auth: AuthenticationService
    
    @StateObject var alertDataHandler = AlertDataHandler.shared
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body : some View {
        NavigationStack {
            VStack(spacing: 64) {
                Image("Logo")
                VStack(spacing: 12) {
                    TextField("Username", text: $username)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .font(.custom("DIN Alternate", size: 18))
                        .lineLimit(1...3)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                        .background(Color("ThemeGray").opacity(0.5))
                        .cornerRadius(12)
                        .frame(maxWidth: 300)
                    SecureField("Password", text: $password)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .font(.custom("DIN Alternate", size: 18))
                        .lineLimit(1...3)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                        .background(Color("ThemeGray").opacity(0.5))
                        .cornerRadius(12)
                        .frame(maxWidth: 300)
                    Button {
                        Task {
                            await logIn()
                        }
                    } label: {
                        Spacer()
                        Text("Entra")
                            .foregroundColor(.white)
                            .font(.custom("DIN Alternate", size: 18))
                        Spacer()
                    }
                    .padding(12)
                    .background(Color("CameraYellow"))
                    .cornerRadius(12)
                    .frame(maxWidth: 300)
                    .opacity((username.isValidUsername() && password.count >= 8) ? 1 : 0.5)
                    .disabled(!(username.isValidUsername() && password.count >= 8))

                    NavigationLink(destination: SignUpView()) {
                        HStack {
                            Text("Non hai un account?")
                                .foregroundColor(Color(UIColor.label))
                                .font(.custom("DIN Alternate", size: 18))
                            Text("Iscriviti")
                                .foregroundColor(Color("CameraYellow"))
                                .font(.custom("DIN Alternate", size: 18))
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarHidden(true)
        }
    }
    
    func logIn() async {
        do {
            let parameters: [String: Any] = [
                "username": username,
                "password": password
            ]
            
            let (responseData, response) = try await Rest.postFormEncoded(endPoint: "login", data: parameters)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 500 {
                throw LoginError.unknown("Errore sconosciuto. Prova a riavviare l'app.")
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                throw LoginError.userNotFound("Questo utente non esiste.")
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
                throw LoginError.missingCredentials("Credenziali non valide.")
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                throw LoginError.invalidCredentials(("Credenziali non valide."))
            }
                        
            let loginPostResponse = try JSONDecoder().decode(LoginPostResponse.self, from: responseData)
                        
            UserDefaults.standard.setValue(loginPostResponse.id, forKey: "user_id")
            UserDefaults.standard.setValue(loginPostResponse.sessionKey, forKey: "session_key")
                        
            let _ = try await UserDataModel.shared.fetch(key: loginPostResponse.id)
            let _ = try await TravelDataModel.shared.fetchAll(userId: loginPostResponse.id)
            
            withAnimation {
                auth.isLogged = true
            }
        } catch {
            print(error)
            
            alertDataHandler.showInfoAlert(
                title: "Impossibile accedere!",
                message: error.localizedDescription,
                onOk: {}
            )
        }
    }
}
