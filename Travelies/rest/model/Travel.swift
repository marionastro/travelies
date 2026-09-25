//
//  Travel.swift
//  mockup
//
//  Created by Studente on 18/07/24.
//

import Foundation

enum TravelPrivacy : Int {
    case PUBLIC = 0
    case PRIVATE = 1
}

struct Travel : JSONEntity, Comparable {
    let id: Int
    let name: String
    let creator: User
    var privacy: Int
    var posts: Array<Post>?
    var members: Array<User>?
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id &&
               lhs.posts == rhs.posts &&
               lhs.members == rhs.members &&
               lhs.privacy == rhs.privacy
    }
    
    static func < (lhs: Travel, rhs: Travel) -> Bool {
        let lhsName = lhs.name.lowercased()
        let rhsName = rhs.name.lowercased()
        
        
        return lhsName < rhsName
    }
    
    func isMember(userId: Int) -> Bool {
        if let members = members {
            return members.contains(where: { $0.id == userId })
        }
        
        return false
    }
    
    func isMember(user: User) -> Bool {
        isMember(userId: user.id)
    }
    
    mutating func addMember(member: User) {
        if (members == nil) {
            members = []
        }
        
        if (!(members!.contains(member))) {
            members!.append(member)
        }
    }
    
    mutating func removeMember(member: User) {
        guard var unwrappedMembers = members else {
            return
        }
        
        if let index = unwrappedMembers.firstIndex(of: member) {
            unwrappedMembers.remove(at: index)
        }
    }
    
    mutating func addPost(post: Post) {
        if (posts == nil) {
            posts = []
        }
        
        if (!(posts!.contains(post))) {
            posts!.append(post)
        }
    }
    
    mutating func removePost(post: Post) {
        guard var unwrappedPosts = posts else {
            return
        }
        
        if let index = unwrappedPosts.firstIndex(of: post) {
            unwrappedPosts.remove(at: index)
        }
    }
    
    func getStartAndEndDateTimes() -> (DateTime, DateTime)? {
        guard let posts = posts else {
            return nil
        }
        
        let dateTimes = posts
            .map({ DateTime(of: $0.time) })
            .sorted(by: { $0 < $1 })

        guard let start = dateTimes.first, let end = dateTimes.last else {
            return nil
        }
        
        return (start, end)
    }
    
    //Mediana geografica
    func getCenter() -> (Double, Double)? {
        guard let posts = posts else {
            return nil
        }
            
        let lats = posts.map{ $0.lat }.compactMap{ $0 }.filter{ abs($0) <= 90 } //ignore wrong latitude values
        let lons = posts.map{ $0.lon }.compactMap{ $0 }.filter{ abs($0) <= 180 } //ignore wrong longitude values
            
        guard let medianLat = getMedian(of: lats),
                let medianLon = getMedian(of: lons)
        else {
            return nil
        }

        return (medianLat, medianLon)
    }
    
    private func getMedian(of values: [Double]) -> Double? {
        guard !values.isEmpty else {
            return nil
        }
        
        let sortedValues = values.sorted()
        let count = sortedValues.count

        return sortedValues[count/2] //avoid weird centers if only two posts far apart
    }
}
