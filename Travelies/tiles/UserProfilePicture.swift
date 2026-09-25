//
//  UserProfilePicture.swift
//  mockup
//
//  Created by Studente on 28/07/24.
//

import Foundation
import SwiftUI

struct UserProfilePicture: View {
    let text: String
    let size: CGFloat
    var color: Color {
        //lunghezza della stringa
        let length = text.count
        
        //vocali nella stringa
        let vowels = "aeiouAEIOU"
        let vowelCount = text.filter { vowels.contains($0) }.count
        
        //somma dei valori ASCII dei caratteri
        let asciiSum = text.unicodeScalars.map { Int($0.value) }.reduce(0, +)
        
        //combinazione per avere un numero tra 0 e 11
        let combinedValue = (length + vowelCount + asciiSum) % 12
        
        switch(combinedValue) {
            case 1: return Color.indigo
            case 2: return Color.blue
            case 3: return Color.red
            case 4: return Color.yellow
            case 5: return Color.orange
            case 6: return Color.cyan
            case 7: return Color.purple
            case 8: return Color.pink
            case 9: return Color.mint
            case 10: return Color.teal
            case 11: return Color.green
            default: return Color("CameraYellow")
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: size * 1.1, height: size * 1.1)
                .foregroundColor(Color("ThemeGray"))
            Circle()
                .frame(width: size, height: size)
                .foregroundColor(Color(UIColor.systemBackground))
            Circle()
                .fill(color.gradient)
                .frame(width: size * 0.8, height: size * 0.8)
            Text(getInitialsString())
                .font(.custom(
                    "DIN Alternate",
                    size: size * (0.5 - getWordsCount() * 0.075)
                ))
                .foregroundColor(UIColor(color).isLight(threshold: 0.8) ?? false ? .black : .white)
        }
    }
    
    func getWordsCount() -> CGFloat {
        return CGFloat(text.split(separator: " ").count)
    }
    
    func getInitialsString() -> String {
        return text.split(separator: " ")
            .map({ $0.prefix(1) })
            .joined(separator: "")
    }
}

extension UIColor {
    // Check if the color is light or dark, as defined by the injected lightness threshold.
    // Some people report that 0.7 is best. I suggest to find out for yourself.
    // A nil value is returned if the lightness couldn't be determined.
    func isLight(threshold: Float = 0.5) -> Bool? {
        let originalCGColor = self.cgColor

        // Now we need to convert it to the RGB colorspace. UIColor.white / UIColor.black are greyscale and not RGB.
        // If you don't do this then you will crash when accessing components index 2 below when evaluating greyscale colors.
        let RGBCGColor = originalCGColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
        guard let components = RGBCGColor?.components else {
            return nil
        }
        guard components.count >= 3 else {
            return nil
        }

        let brightness = Float(((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000)
        return (brightness > threshold)
    }
}
