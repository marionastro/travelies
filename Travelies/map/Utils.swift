//
//  BaseMap.swift
//  mockup
//
//  Created by Studente on 30/08/24.
//

import SwiftUI
import MapKit

//return the distance in meters between two geographic coordinates
    //using havesine formul
func calucateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double{
    let lat1Rad = degreeToRad(lat1)
    let lon1Rad = degreeToRad(lon1)
    let lat2Rad = degreeToRad(lat2)
    let lon2Rad = degreeToRad(lon2)
    
    let EarthRadius = 6371.0 * 1000  //m
    
    //a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
    let haversine = pow(sin( (lat1Rad - lat2Rad) )/2 ,2) + cos(lat1Rad)*cos(lat2Rad)*pow(sin( (lon1Rad - lon2Rad) )/2 ,2)
    
    let c = 2 * atan2( sqrt(haversine), sqrt(1 - haversine) )
    //let c = 2*asin(haversine)
    
    return EarthRadius*c
}

func degreeToRad(_ number: Double) -> Double {
    return number * .pi / 180
}
