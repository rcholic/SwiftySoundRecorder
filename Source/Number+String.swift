//
//  Number+String.swift
//  SwiftySoundRecorder
//
//  Created by Guoliang Wang on 8/13/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation

extension Int {
    func addLeadingZeroAsString() -> String {
        return String(format: "%02d", self)  // add leading zero to single digit
    }
}

extension Double {
    
    func stripDecimalZeroAsString() -> String? {
        if self >= 1 || self == 0 {
            return nil
        }
        let formatter = NSNumberFormatter()
        formatter.positiveFormat = ".###" // decimal without decimal 0
        
        return formatter.stringFromNumber(self) // 0.333454 becomes ".333"
    }
}
