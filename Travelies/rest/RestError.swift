//
//  RestError.swift
//  mockup
//
//  Created by Studente on 01/09/24.
//

import Foundation

enum RestError : Error {
    case unknown(_ message: String)
    case cannotConnect(_ message: String)
    case invalidParameters(_ message: String)
    case unauthorized(_ message: String)
    case notFound(_ message: String)
}

extension RestError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknown(let message),
             .cannotConnect(let message),
             .invalidParameters(let message),
             .unauthorized(let message),
             .notFound(let message):
            return message
        }
    }
}

