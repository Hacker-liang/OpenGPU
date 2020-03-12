//
//  OGFramebuffer.swift
//  MWVideoRecord
//
//  Created by langren on 2019/8/29.
//  Copyright © 2019 langren. All rights reserved.
//

import UIKit

class OGFramebuffer {
    
    public weak var framebufferCache: OGFramebufferCache?
    
    public var tag: String?
    
    private weak var context: OGEAGLContext?
    
    private (set) var hash: Int64 = 0
    
    private var framebufferRetainCount = 0

    //attach texture buffer to fbo
    private (set) var texture: GLuint?
    
    //fbo
    private var framebuffer: GLuint?
    
    //attach stencil buffer to fbo
    private var stencilBuffer: GLuint?
    
    init(context: OGEAGLContext, orentation: OGImageOrientation, size: CGSize, textureOnly: Bool = false, minFilter: Int32 = GL_LINEAR, maxFilter: Int32 = GL_LINEAR, wrapS: Int32 = GL_CLAMP_TO_EDGE, wrapT: Int32 = GL_CLAMP_TO_EDGE, internalFormat: Int32 = GL_RGBA, format: Int32 = GL_BGRA, type: Int32 = GL_UNSIGNED_BYTE, stencilTest: Bool = false, overrideTexture: GLuint? = nil) {
        
        if let newTexture = overrideTexture {
            self.texture = newTexture
        } else {
            self.texture = generate2DTexture(minFilter: minFilter, maxFilter: maxFilter, wrapS: wrapS, wrapT: wrapT)
        }
        self.context = context
        if !textureOnly {  //if not only create texture, then create fbo
            self.createFramebuffer(texture: texture!, width: GLint(size.width), height: GLint(size.height), internalformat: internalFormat, format: format, type: type)
        } else {
            framebuffer = nil
            stencilBuffer = nil
        }
        self.hash = OGFramebuffer.hashValue(orentation: orentation, size: size, textureOnly: textureOnly, minFilter: minFilter, maxFilter: maxFilter, wrapS: wrapS, wrapT: wrapT, internalFormat: internalFormat, format: format, type: type, stencilTest: stencilTest)
        
    }
    
    private func createFramebuffer(texture: GLuint, stencilTest: Bool = false, width: GLint, height: GLint, internalformat: Int32, format: Int32, type: Int32) {
        var framebuffer: GLuint = 0
        
        glActiveTexture(GLenum(GL_TEXTURE1))
        
        glGenFramebuffers(1, &framebuffer)
        glBindBuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        glBindTexture(GLenum(GL_TEXTURE_2D), texture)
        
        //为texture分配空间，但是不填充，由fbo渲染完之后自动填充
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, internalformat, width, height, 0, GLenum(format), GLenum(type), nil)
        //attach texture to fbo as color buffer
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), texture, 0)
        
        let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
        if status != GLenum(GL_FRAMEBUFFER_COMPLETE) {
            print("create fbo error")
        }
        
        if stencilTest {
            self.stencilBuffer = createAndAttach2FBOStencilBuffer(width: width, height: height)
        }
        //unbind texture
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        //unbind fbo
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
        self.framebuffer = framebuffer
    }
    
    //引用计数+1
    public func retain() {
        framebufferRetainCount += 1
    }
    
    //引用计数-1
    public func release() {
        framebufferRetainCount -= 1
        if framebufferRetainCount <= 0 {
            framebufferRetainCount = 0
            framebufferCache?.retureToCache(framebuffer: self)
        }
        
    }
}

extension OGFramebuffer {
    
    //根据纹理的不同设置，计算出纹理的hash值
    public class func hashValue(orentation: OGImageOrientation, size: CGSize, textureOnly: Bool = false, minFilter: Int32 = GL_LINEAR, maxFilter: Int32 = GL_LINEAR, wrapS: Int32 = GL_CLAMP_TO_EDGE, wrapT: Int32 = GL_CLAMP_TO_EDGE, internalFormat: Int32 = GL_RGBA, format: Int32 = GL_BGRA, type: Int32 = GL_UNSIGNED_BYTE, stencilTest: Bool = false) ->Int64 {
        var result: Int64 = 1
        let prime: Int64 = 31
        let yesPrime: Int64 = 131
        let noPrime: Int64 = 231
        
        result = prime*result + Int64(size.width)
        result = prime*result + Int64(size.height)
        result = prime*result + Int64(internalFormat)
        result = prime*result + Int64(format)
        result = prime*result + Int64(type)
        result = prime*result + Int64(minFilter)
        result = prime*result + Int64(maxFilter)
        result = prime*result + Int64(wrapS)
        result = prime*result + Int64(wrapT)
        result = prime * result + (textureOnly ? yesPrime : noPrime)
        result = prime * result + (stencilTest ? yesPrime : noPrime)
        
        return result
    }
}
