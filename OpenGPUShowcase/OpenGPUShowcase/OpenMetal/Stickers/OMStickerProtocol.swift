//
//  OMStickerProtocol.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/23.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

protocol OMStickerProtocol {
    
    var width: Float { get }
    
    var height: Float { get }
    
    var texture: OMTexture? { get }
    
    var index: Int? { get }
    
    var stickerName: String? { get }
    
    var showDuration: Float { get }
    
}
