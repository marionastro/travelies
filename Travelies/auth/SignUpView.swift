//
//  SignUpView.swift
//  mockup
//
//  Created by Studente on 25/07/24.
//

import Foundation
import SwiftUI

struct SignUpPostResponse : Decodable {
    let id: String
    let sessionKey: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionKey = "session_key"
    }
}

struct SignUpView : View {
    @EnvironmentObject var auth: AuthenticationService
    @Environment(\.presentationMode) var presentation
    
    @StateObject var alertDataHandler = AlertDataHandler.shared
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""
    
    var body : some View {
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
                Text("L'username deve essere lungo tra i 3 e i 16 caratteri.")
                    .font(.custom("DIN Alternate", size: 12))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                TextField("E-mail", text: $email)
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
                SecureField("Conferma Password", text: $passwordConfirm)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .font(.custom("DIN Alternate", size: 18))
                    .lineLimit(1...3)
                    .multilineTextAlignment(.leading)
                    .padding(12)
                    .background(Color("ThemeGray").opacity(0.5))
                    .cornerRadius(12)
                    .frame(maxWidth: 300)
                Text("La password deve essere lunga almeno 6 caratteri.")
                    .font(.custom("DIN Alternate", size: 12))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Button {
                    Task {
                        await signUp()
                    }
                } label: {
                    Spacer()
                    Text("Crea account")
                        .foregroundColor(.white)
                        .font(.custom("DIN Alternate", size: 18))
                    Spacer()
                }
                .padding(12)
                .background(Color("CameraYellow"))
                .cornerRadius(12)
                .frame(maxWidth: 300)
                .opacity(isFormValid() ? 1 : 0.5)
                .disabled(!isFormValid())
                
                NavigationLink(destination: LoginView()) {
                    HStack {
                        Text("Hai già un account?")
                            .foregroundColor(Color(UIColor.label))
                            .font(.custom("DIN Alternate", size: 18))
                        Text("Accedi")
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
    
    func isFormValid() -> Bool {
        (
            username.isValidUsername() &&
            email.isValidEmail() &&
            password.count >= 8 &&
            password == passwordConfirm
        )
    }
    
    func signUp() async {
        do {
            let parameters: [String: Any] = [
                "username": username.lowercased(),
                "email": email.lowercased(),
                "password": password
            ]
            
            let (responseData, response) = try await Rest.postFormEncoded(endPoint: "signup", data: parameters)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 500 {
                throw LoginError.unknown("Errore sconosciuto. Prova a riavviare l'app.")
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
                throw LoginError.missingCredentials("Credenziali non valide.")
            }
                        
            let signUpPostResponse = try JSONDecoder().decode(SignUpPostResponse.self, from: responseData)
            
            guard let userId = Int(signUpPostResponse.id) else {
                throw LoginError.unknown("Credenziali non valide o già in uso.")
            }
                        
            UserDefaults.standard.setValue(userId, forKey: "user_id")
            UserDefaults.standard.setValue(signUpPostResponse.sessionKey, forKey: "session_key")
            
            let _ = try await UserDataModel.shared.fetch(key: userId)
            let _ = try await TravelDataModel.shared.fetchAll(userId: userId)
            
            withAnimation {
                auth.isLogged = true
            }
        } catch {
            print(error)
            
            alertDataHandler.showInfoAlert(
                title: "Impossibile creare l'account",
                message: error.localizedDescription,
                onOk: {}
            )
        }
    }
}

extension String {
    func isValidUsername() -> Bool {
        return NSPredicate(format:"SELF MATCHES %@", "^[a-zA-Z0-9]{3,16}$")
            .evaluate(with: self)
    }
    
    func isValidEmail() -> Bool {
        return NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
            .evaluate(with: self)
    }
}
