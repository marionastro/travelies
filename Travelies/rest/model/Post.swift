//
//  Post.swift
//  mockup
//
//  Created by Studente on 18/07/24.
//

import Foundation
import UIKit

struct Post : JSONEntity, Comparable {
    let id: Int
    let time: String
    let lat: Double?
    let lon: Double?
    let dataPath: String
    let dataType: Int
    let user: User
        
    func getDateTimeObject() -> DateTime {
        return DateTime(of: time)
    }
    
    static func < (lhs: Post, rhs: Post) -> Bool {
        let lhsDateTime = lhs.getDateTimeObject()
        let rhsDateTime = rhs.getDateTimeObject()
        
        return lhsDateTime < rhsDateTime
    }
    
    public static func bounds(for posts: [Post]?) -> (maxLat: Double, minLat: Double, maxLon: Double, minLon: Double) {
        let maxLat = posts?.compactMap { $0.lat }.max() ?? 0.0
        let minLat = posts?.compactMap { $0.lat }.min() ?? 0.0
        let maxLon = posts?.compactMap { $0.lon }.max() ?? 0.0
        let minLon = posts?.compactMap { $0.lon }.min() ?? 0.0
            
        
        return (maxLat, minLat, maxLon, minLon)
    }
}

enum Month: Int, CaseIterable {
    case JANUARY    = 1
    case FEBRUARY   = 2
    case MARCH      = 3
    case APRIL      = 4
    case MAY        = 5
    case JUNE       = 6
    case JULY       = 7
    case AUGUST     = 8
    case SEPTEMBER  = 9
    case OCTOBER    = 10
    case NOVEMBER   = 11
    case DECEMBER   = 12
    
    func toItString() -> String {
        switch (self) {
            case .JANUARY   : "Gennaio"
            case .FEBRUARY  : "Febbraio"
            case .MARCH     : "Marzo"
            case .APRIL     : "Aprile"
            case .MAY       : "Maggio"
            case .JUNE      : "Giugno"
            case .JULY      : "Luglio"
            case .AUGUST    : "Agosto"
            case .SEPTEMBER : "Settembre"
            case .OCTOBER   : "Ottobre"
            case .NOVEMBER  : "Novembre"
            case .DECEMBER  : "Dicembre"
        }
    }
    
    func toItShortString() -> String {
        return String(toItString().prefix(3))
    }
}

struct DateTime : Comparable {
    let day: Int
    let month: Int
    let year: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
    
    init(of: String) {
        let strArr = of.split(separator: " ")
        let dateArr = strArr[0].split(separator: "-")
        let timeArr = strArr[1].split(separator: ":")
        
        self.day   = Int(dateArr[2]) ?? 1
        self.month = Int(dateArr[1]) ?? 1
        self.year  = Int(dateArr[0]) ?? 1970
        
        self.hours   = Int(timeArr[0]) ?? 0
        self.minutes = Int(timeArr[1]) ?? 0
        self.seconds = Int(timeArr[2]) ?? 0
    }
    
    func toMonthDateString() -> String {
        return "\(day) \(Month(rawValue: month)!.toItString()) \(year)"
    }
    
    func toShortMonthDateString() -> String {
        return "\(day) \(Month(rawValue: month)!.toItShortString()) \(year)"
    }
    
    func toDateString() -> String {
        return "\(day)/\(month)/\(year)"
    }
    
    func toTimeString(showSeconds: Bool) -> String {
        return "\(hours):\(minutes)" + (showSeconds ? ":\(seconds)" : "")
    }
    
    func toString() -> String {
        return "\(toDateString()) \(toTimeString(showSeconds: true))"
    }
    
    static func == (lhs: DateTime, rhs: DateTime) -> Bool {
        return (lhs.year == rhs.year &&
                lhs.month == rhs.month &&
                lhs.day == rhs.day &&
                lhs.hours == rhs.hours &&
                lhs.minutes == rhs.minutes &&
                lhs.seconds == rhs.seconds)
    }
    
    static func < (lhs: DateTime, rhs: DateTime) -> Bool {
        if (lhs.year != rhs.year) {
            return lhs.year < rhs.year
        }
        
        if (lhs.month != rhs.month) {
            return lhs.month < rhs.month
        }
        
        if (lhs.day != rhs.day) {
            return lhs.day < rhs.day
        }
        
        if (lhs.hours != rhs.hours) {
            return lhs.hours < rhs.hours
        }
        
        if (lhs.minutes != rhs.minutes) {
            return lhs.minutes < rhs.minutes
        }
        
        if (lhs.day != rhs.day) {
            return lhs.day < rhs.day
        }
        
        return false
    }
}
