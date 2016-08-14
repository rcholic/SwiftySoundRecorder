//
//  Cropper.swift
//  SwiftySoundRecorder
//
//  Created by Guoliang Wang on 8/13/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import Foundation

internal enum CropperType {
    case Left
    case Right
}

public class Cropper: UIView {
    public var cropTime: CGFloat {
        set {
            if newValue > 0 {
                let second = (Int((newValue % 3600) % 60))
                let minute = (Int((newValue % 3600) / 60))
                let hour = (Int(newValue / 3600))
                let milisec = newValue - CGFloat(hour * 3600) - CGFloat(minute * 60) - CGFloat(second)
                let miliSecStr = Double(milisec).stripDecimalZeroAsString() ?? ""
                self._cropTime = newValue
                if hour == 0 {
                    self.timeLabel.text = "\(minute.addLeadingZeroAsString()):\(second.addLeadingZeroAsString())\(miliSecStr)"
                } else {
                    self.timeLabel.text = "\(hour.addLeadingZeroAsString()):\(minute.addLeadingZeroAsString()):\(second.addLeadingZeroAsString())\(miliSecStr)"
                }
            } else {
                self._cropTime = 0 // default to 0 if assigned negative vlue
                self.timeLabel.text = "00:00"
            }
        }
        get {
            return self._cropTime
        }
    }
    
    var verticalLine: UIView = UIView()
    var horizontalLine: UIView = UIView()
    var lineColor: UIColor = UIColor.redColor()
    var lineThickness: CGFloat = 2
    var height: CGFloat = 90.0
    var width: CGFloat = 30.0
    var cropperType: CropperType = .Left
    let timeLabel: UILabel = UILabel()
    let labelHeight: CGFloat = 20
    var _cropTime: CGFloat = 0
    
    init(cropperType: CropperType, lineThickness: CGFloat = 2, lineColor: UIColor = UIColor.redColor()) {
        self.cropperType = cropperType
        self.lineThickness = lineThickness
        self.lineColor = lineColor
        super.init(frame: CGRectNull)
        setupUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first
        let p = (touch?.locationInView(self))!
        print("coord: \(p.x), \(p.y)")
    }
    
    private func setupUI() {
        self.cropTime = 0
        timeLabel.text = "00:00"
        timeLabel.textColor = self.lineColor
        timeLabel.font = UIFont(name: "San Francisco", size: 10)
        timeLabel.adjustsFontSizeToFitWidth = true
    }
    
    func setTimeLabel(timeText time: String?) {
        self.timeLabel.text = time
    }
    
    override public func drawRect(rect: CGRect) {
        print("drawRect, rect bounds: \(rect.width), \(rect.height)")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundColor = UIColor.clearColor()
        
        positionViews()
    }
    
    func positionViews() {
        // left Verticalline and Horizontal line as default
        timeLabel.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: labelHeight)
        verticalLine = UIView(frame: CGRect(x: 0, y: labelHeight, width: lineThickness, height: self.bounds.height - lineThickness - labelHeight))
        verticalLine.backgroundColor = lineColor
        horizontalLine = UIView(frame: CGRect(x: 0, y: self.bounds.height-lineThickness, width: self.bounds.width, height: lineThickness))
        horizontalLine.backgroundColor = lineColor
        
        switch self.cropperType {
        case .Right:
            timeLabel.frame = CGRect(x: 0, y: self.bounds.height-labelHeight, width: width, height: labelHeight)
            let maxX = self.bounds.width - lineThickness
            verticalLine.frame = CGRect(x: maxX, y: 0, width: lineThickness, height: self.bounds.height - labelHeight)
            horizontalLine.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: lineThickness)
            
        default:
            print("using Left cropper as default")
        }
        
        self.addSubview(timeLabel)
        self.addSubview(verticalLine)
        self.addSubview(horizontalLine)
    }

}
