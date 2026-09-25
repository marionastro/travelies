//
//  AuthenticationService.swift
//  mockup
//
//  Created by Studente on 16/08/24.
//

import Foundation

public class AuthenticationService : ObservableObject {
    @Published public var isLogged: Bool = false
    
    func logOut() {
        UserDefaults.standard.removeObject(forKey: "session_key")

        isLogged = false
    }
}
