//
//  Configuration.swift
//  SwiftySoundRecorder
//
//  Created by Guoliang Wang on 8/13/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

public struct Configuration {
    // MARK Colors
    public static var defaultBlueTintColor = UIColor(red: 14, green: 122, blue: 254, alpha: 1)
    public static var recorderWaveNormalTintColor = defaultBlueTintColor
    
    public static var darkOrangeColor = UIColor(red: 255, green: 140, blue: 0, alpha: 1)
    
    public static var recorderWaveHighlightedTintColor = darkOrangeColor
    
    public static var cropperLineColor = UIColor.redColor()
    // MARK Fonts
    
    
    // MARK Titles
    public static var navBarButtonLabelsDict: [String : String ] = ["Cancel": "Cancel", "Done": "Done"]
    
    public static var originalRecordingFileName: String = "recording"
    public static var trimmedRecordingFileName: String = "recording_trimmed"
    
    // MARK Dimensions
    public static var cropperLineThickness: CGFloat = 2
    public static var navBarHeight: CGFloat = 45
    
    
    // MARK images
    public static var milkyWayImage: UIImage = UIImage(named: "milkyway.jpg")!
}
