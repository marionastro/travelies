//
//  Entity.swift
//  mockup
//
//  Created by Studente on 18/07/24.
//

import Foundation

protocol JSONEntity: Hashable, Decodable, Identifiable, Equatable {}

extension JSONEntity {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
