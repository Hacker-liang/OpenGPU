//
//  OGColor.swift
//  MWVideoRecord
//
//  Created by langren on 2019/8/29.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation

public struct OGColor {
    public let red:Float
    public let green:Float
    public let blue:Float
    public let alpha:Float
    
    public init(red:Float, green:Float, blue:Float, alpha:Float = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public static let black = OGColor(red:0.0, green:0.0, blue:0.0, alpha:1.0)
    public static let white = OGColor(red:1.0, green:1.0, blue:1.0, alpha:1.0)
    public static let red = OGColor(red:1.0, green:0.0, blue:0.0, alpha:1.0)
    public static let green = OGColor(red:0.0, green:1.0, blue:0.0, alpha:1.0)
    public static let blue = OGColor(red:0.0, green:0.0, blue:1.0, alpha:1.0)
    public static let transparent = OGColor(red:0.0, green:0.0, blue:0.0, alpha:0.0)
}
