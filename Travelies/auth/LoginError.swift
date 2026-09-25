//
//  LoginError.swift
//  mockup
//
//  Created by Studente on 02/09/24.
//

import Foundation

enum LoginError : Error {
    case unknown(_ message: String)
    case userNotFound(_ message: String)
    case missingCredentials(_ message: String)
    case invalidCredentials(_ message: String)
}

extension LoginError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknown(let message),
             .userNotFound(let message),
             .missingCredentials(let message),
             .invalidCredentials(let message):
            return message
        }
    }
}
