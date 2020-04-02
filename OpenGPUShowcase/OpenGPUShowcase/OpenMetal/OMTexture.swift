//
//  OMTexture.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/30.
//  Copyright © 2020 langren. All rights reserved.
//

import Foundation
import MetalKit

class OMTexture {
    
    private (set) var texture: MTLTexture?
    
    init(texture: MTLTexture) {
        self.texture = texture
    }
    
    init(device: MTLDevice, width: Int, height: Int, oreation: Int) {
         let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                                width: width,
                                                                                height: height,
                                                                                mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]

        self.texture = device.makeTexture(descriptor: textureDescriptor)
        if self.texture == nil {
            print("texture nil")
        }
    }
}
