//
//  OMPipline.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/30.
//  Copyright © 2020 langren. All rights reserved.
//

import Foundation


protocol OMImageProvider {
    
    var allTargets: [OMImageConsumer]  { get }
    
    func addTarget(target: OMImageConsumer)
    
}

extension OMImageProvider {
    func updateAllTargets(texture: OMTexture) {
        allTargets.forEach { (target) in
            target.newTextureAvailable(texture: texture, atIndex: 0)
        }
    }
}

protocol OMImageConsumer {
    
    func newTextureAvailable(texture: OMTexture, atIndex: UInt)
    
}
