//
//  User.swift
//  mockup
//
//  Created by Studente on 18/07/24.
//

import SwiftUI
import Foundation

struct User: JSONEntity {
    let id: Int
    let username: String
    let email: String
    var friends: Array<User>?
    
    func isFriend(user: User) -> Bool {
        ((friends?.contains(user)) != nil)
    }
    
    mutating func addFriend(friend: User) {
        if (friends == nil) {
            friends = []
        }
        
        if (!(friends!.contains(friend))) {
            friends!.append(friend)
        }
    }
    
    mutating func removeFriend(friend: User) {
        guard var unwrappedFriends = friends else {
            return
        }
        
        if let index = unwrappedFriends.firstIndex(of: friend) {
            unwrappedFriends.remove(at: index)
        }
    }
}
