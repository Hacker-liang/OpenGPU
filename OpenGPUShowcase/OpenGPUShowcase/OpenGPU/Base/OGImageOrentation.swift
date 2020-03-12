//
//  OGImageOrentation.swift
//  MWVideoRecord
//
//  Created by langren on 2019/8/29.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation

public enum OGImageOrientation {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
    
    func rotationNeededForOrientation(_ targetOrientation: OGImageOrientation) -> OGRotation {
        switch (self, targetOrientation) {
        case (.portrait, .portrait), (.portraitUpsideDown, .portraitUpsideDown), (.landscapeLeft, .landscapeLeft), (.landscapeRight, .landscapeRight): return .noRotation
        case (.portrait, .portraitUpsideDown): return .rotate180
        case (.portraitUpsideDown, .portrait): return .rotate180
        case (.portrait, .landscapeLeft): return .rotateCounterclockwise
        case (.landscapeLeft, .portrait): return .rotateClockwise
        case (.portrait, .landscapeRight): return .rotateClockwise
        case (.landscapeRight, .portrait): return .rotateCounterclockwise
        case (.landscapeLeft, .landscapeRight): return .rotate180
        case (.landscapeRight, .landscapeLeft): return .rotate180
        case (.portraitUpsideDown, .landscapeLeft): return .rotateClockwise
        case (.landscapeLeft, .portraitUpsideDown): return .rotateCounterclockwise
        case (.portraitUpsideDown, .landscapeRight): return .rotateCounterclockwise
        case (.landscapeRight, .portraitUpsideDown): return .rotateClockwise
        }
    }
}

public enum OGRotation {
    case noRotation
    case rotateCounterclockwise
    case rotateClockwise
    case rotate180
    case flipHorizontally
    case flipVertically
    case rotateClockwiseAndFlipVertically
    case rotateClockwiseAndFlipHorizontally
    
    func flipsDimensions() -> Bool {
        switch self {
        case .noRotation, .rotate180, .flipHorizontally, .flipVertically: return false
        case .rotateCounterclockwise, .rotateClockwise, .rotateClockwiseAndFlipVertically, .rotateClockwiseAndFlipHorizontally: return true
        }
    }
}
