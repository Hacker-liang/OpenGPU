//
//  OGRenderHelper.swift
//  MWVideoRecord
//
//  Created by langren on 2019/8/29.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation
import OpenGLES

public func clearFramebufferColor(color: OGColor) {
    glClearColor(color.red, color.green, color.blue, color.alpha)
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
}

public func generate2DTexture(minFilter: Int32, maxFilter: Int32, wrapS: Int32, wrapT: Int32) -> GLuint {
    var texture: GLuint = 0
    glActiveTexture(GLenum(GL_TEXTURE1))
    glGenTextures(1, &texture)
    glBindTexture(GLenum(GL_TEXTURE_2D), texture)
    
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), minFilter)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), maxFilter)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), wrapS)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), wrapT)
    
    //unbind
    glBindTexture(GLenum(GL_TEXTURE_2D), 0)

    return texture
}

//create 模板测试buffer，并attach到当前绑定的fbo
public func createAndAttach2FBOStencilBuffer(width: GLint, height: GLint) -> GLuint {
    var stencilBuffer: GLuint = 0
    glGenRenderbuffers(1, &stencilBuffer)
    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), stencilBuffer)
    glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH24_STENCIL8), width, height)
    glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), stencilBuffer)
    glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_STENCIL_ATTACHMENT), GLenum(GL_RENDERBUFFER), stencilBuffer)
    // unbind
    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), 0)
    let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
    if status != GLenum(GL_FRAMEBUFFER_COMPLETE) {
        print("error create stencil buffer")
    }
    return stencilBuffer
}

public func renderQuad(withProgram program: OGShaderProgram, vertices:[GLfloat], textures: [(textureId:GLuint, textureCoordinate:[GLfloat])]) {
    OGEAGLContext.shared().makeCurrentContext()
    program.use()
    
    guard let vertextLocation = program.attributeLocation(attribute: "position") else {
        assertionFailure()
        return
    }
    
    glVertexAttribPointer(vertextLocation, 2, GLenum(GL_FLOAT), 0, 0, vertices)
    
    for (i,textureItem) in textures.enumerated() {
        guard let textureLocation = program.attributeLocation(attribute: "inputTextureCoordinate".withNonZeroSuffix(i)) else {
            break
        }
        //上传纹理坐标
        glVertexAttribPointer(textureLocation, 2, GLenum(GL_FLOAT), 0, 0, textureItem.textureCoordinate)
        glActiveTexture(GLenum(GL_TEXTURE0+Int32(i)))
        glBindTexture(GLenum(GL_TEXTURE_2D), textureItem.textureId)
        //上传纹理数据
        program.setValue(value: GLint(i), forUniform: "inputImageTexture".withNonZeroSuffix(i))
    }
    
    glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
    
    //unbind
//    glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0);
    for (index, _) in textures.enumerated() {
        glActiveTexture(GLenum(GLint(index)))
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    }
}

extension String {
    func withNonZeroSuffix(_ suffix:Int) -> String {
        if suffix == 0 {
            return self
        } else {
            return "\(self)\(suffix + 1)"
        }
    }
}




