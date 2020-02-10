//
//  UICustom.swift
//  Amsel
//
//  Created by Anja on 21.11.19.
//  Copyright © 2019 Anja. All rights reserved.
//

import UIKit

@IBDesignable
class CustomSlider : UISlider {
    
    // Slider thickness
    @IBInspectable
    var trackWidth: CGFloat = 2 {
        didSet {setNeedsDisplay()}
    }
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        let defaultBounds = super.trackRect(forBounds: bounds)
        return CGRect(
            x: defaultBounds.origin.x,
            y: defaultBounds.origin.y + defaultBounds.size.height/2 - trackWidth/2,
            width: defaultBounds.size.width,
            height: trackWidth
        )
    }
    
    // Slider thumb size
    @IBInspectable
    var thumbSize: CGFloat = 31 {
        didSet {setNeedsDisplay()}
    }
    override open func thumbRect(forBounds bounds: CGRect,
    trackRect rect: CGRect,
        value: Float) -> CGRect {
        let defaultBounds = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        return CGRect(
            x: defaultBounds.origin.x + defaultBounds.size.width/2 - thumbSize/2,
            y: defaultBounds.origin.y + defaultBounds.size.height/2 - thumbSize/2,
            width: thumbSize,
            height: thumbSize
        )
    }
    
    // Slider rotation
    @IBInspectable
    var rotation: Int {
        get {
            return 0
        } set {
            let radians = CGFloat(CGFloat(Double.pi) * CGFloat(newValue) / CGFloat(180.0))
            self.transform = CGAffineTransform(rotationAngle: radians)
        }
    }
}

@IBDesignable
class CustomLabel : UILabel {
    
    // Label rotation
    @IBInspectable
    var rotation: Int {
        get {
            return 0
        } set {
            let radians = CGFloat(CGFloat(Double.pi) * CGFloat(newValue) / CGFloat(180.0))
            self.transform = CGAffineTransform(rotationAngle: radians)
        }
    }
}

@IBDesignable
class CustomImage : UIImageView {
    
    // Label rotation
    @IBInspectable
    var rotation: Int {
        get {
            return 0
        } set {
            let radians = CGFloat(CGFloat(Double.pi) * CGFloat(newValue) / CGFloat(180.0))
            self.transform = CGAffineTransform(rotationAngle: radians)
        }
    }
}
