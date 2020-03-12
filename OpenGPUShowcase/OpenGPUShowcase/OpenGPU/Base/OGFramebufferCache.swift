//
//  OGFramebufferCache.swift
//  MWVideoRecord
//
//  Created by langren on 2019/8/31.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation
import CoreGraphics
import OpenGLES

class OGFramebufferCache {
    private var framebufferCache = [Int64: [OGFramebuffer]]()
    
    private weak var openglContext: OGEAGLContext!
    
    init(context: OGEAGLContext) {
        openglContext = context
    }
}

//MARK: Public
extension OGFramebufferCache {
    public func requestFrameBuffer(orentation: OGImageOrientation, size: CGSize, textureOnly: Bool = false, minFilter: Int32 = GL_LINEAR, maxFilter: Int32 = GL_LINEAR, wrapS: Int32 = GL_CLAMP_TO_EDGE, wrapT: Int32 = GL_CLAMP_TO_EDGE, internalFormat: Int32 = GL_RGBA, format: Int32 = GL_BGRA, type: Int32 = GL_UNSIGNED_BYTE, stencilTest: Bool = false, overridetexture: GLuint? = nil) -> OGFramebuffer {
        let frameBuffer: OGFramebuffer
        let hash = OGFramebuffer.hashValue(orentation: orentation, size: size, textureOnly: textureOnly, minFilter: minFilter, maxFilter: maxFilter, wrapS: wrapS, wrapT: wrapT, internalFormat: internalFormat, format: format, type: type, stencilTest: stencilTest)
        
        //如果cache里有此配置的framebuffer，取出然后返回
        if (framebufferCache[hash]?.count ?? -1) > 0 {
            frameBuffer = self.framebufferCache[hash]!.removeLast()
            
        } else {  //如果没有，根据配置创建framebuffer，然后返回，注意新创建的framebuffer并不会放到cache里。
            frameBuffer = OGFramebuffer(context: self.openglContext, orentation: orentation, size: size, textureOnly: textureOnly, minFilter: minFilter, maxFilter: maxFilter, wrapS: wrapS, wrapT: wrapT, internalFormat: internalFormat, format: format, type: type, stencilTest: stencilTest, overrideTexture: overridetexture)
            frameBuffer.framebufferCache = self
        }
        return frameBuffer
    }
    
    public func retureToCache(framebuffer: OGFramebuffer) {
        openglContext.runOperationSynchronously {
            if let _ = self.framebufferCache[framebuffer.hash] {
                self.framebufferCache[framebuffer.hash]?.append(framebuffer)
            } else {
                self.framebufferCache[framebuffer.hash] = [framebuffer]
            }
        }
    }
    
    public func clearCache() {
        framebufferCache.removeAll()
        //TODO: 进一步对接TextureCache的释放内存的方法 CVOpenGLESTextureCacheFlush
    }
}
