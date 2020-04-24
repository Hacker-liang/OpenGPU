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
    
    private var width: Float = 0.0
    private var height: Float = 0.0
    
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

enum OMTextureUploadError: Error {
    case fileDoesNotExit(filePath: String)
    case metalError
}

extension OMTexture {
    
    class func uploadImage2Texture(filePath: String) throws -> MTLTexture?  {
        guard let image = UIImage(contentsOfFile: filePath), let bitmap = image.cgImage else {
            throw OMTextureUploadError.fileDoesNotExit(filePath: filePath)
        }
        
        let textureLoader = MTKTextureLoader(device: OMRenderDevice.shared().device)
        
        do {
            return try textureLoader.newTexture(cgImage: bitmap, options: [MTKTextureLoader.Option.SRGB: false])
        } catch {
            throw OMTextureUploadError.metalError
        }
    }
}
