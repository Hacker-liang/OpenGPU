//
//  OGRenderView.swift
//  MWVideoRecord
//
//  Created by langren on 2019/8/29.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation
import UIKit

class OGRenderView: UIView {
    public var backgroundRenderColor: OGColor = .red
    public var fillModel: Int = 0
    public var imageOrentation: OGImageOrientation = .portrait
    
    private var displayFramebuffer: GLuint?
    private var displayRenderBuffer: GLuint?
    private var viewPort: CGSize = CGSize.zero
    
    lazy private var displayShader: OGShaderProgram = {
        return OGShaderProgram(vertexShaderString: OGShaderLanguage.vertex.shaderContent(), fragmentShaderString: OGShaderLanguage.framgment.shaderContent())
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configDisplayView()
        OGEAGLContext.shared().runOperationSynchronously {
            self.displayShader = OGShaderProgram(vertexShaderString: OGShaderLanguage.vertex.shaderContent(), fragmentShaderString: OGShaderLanguage.framgment.shaderContent())
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //将当前view的layer设置为eagl类型
    override public class var layerClass:Swift.AnyClass {
        get {
            return CAEAGLLayer.self
        }
    }
    
    private func configDisplayView() {
        //opengl渲染的layer
        let eaglLayer = self.layer as! CAEAGLLayer
        eaglLayer.isOpaque = true
        eaglLayer.drawableProperties = [String(describing: NSNumber(value: false)):kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8: kEAGLDrawablePropertyColorFormat]
        
    }
    
    private func createFramebuffer() {
        var framebuffer: GLuint = 0
        
        //create fbo
        glGenFramebuffers(1, &framebuffer)
        displayFramebuffer = framebuffer
        //bind
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        
        //create rbo
        var renderBuffer: GLuint = 0
        glGenRenderbuffers(1, &renderBuffer)
        displayRenderBuffer = renderBuffer
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
        
        //为rbo分配渲染缓存区
        OGEAGLContext.shared().context.renderbufferStorage(Int(GL_RENDERBUFFER), from: self.layer as! CAEAGLLayer)
        
        var backingWidth: GLint = 0
        var backingHeight: GLint = 0
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_WIDTH), &backingWidth)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_HEIGHT), &backingHeight)
    
        guard backingWidth > 0 && backingHeight > 0 else {
            fatalError("error displaview")
        }
        self.viewPort = CGSize(width: CGFloat(backingWidth), height: CGFloat(backingHeight))
        
        //attach rbo to fbo as color cache
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), renderBuffer)
        
        let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
        if status != GLenum(GL_FRAMEBUFFER_COMPLETE) {
            fatalError("error create fbo")
        }
    }
    
    func activateDisplayFramebuffer() {
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.displayFramebuffer!)
        glViewport(0, 0, GLsizei(viewPort.width), GLsizei(viewPort.height))
    }
}

extension OGRenderView: OGImageConsumer {
    
    func newFramebufferAvailable(framebuffer: OGFramebuffer, fromSourceIndex: uint) {
        if displayFramebuffer == nil {
            self.createFramebuffer()
        }
        self.activateDisplayFramebuffer()
        clearFramebufferColor(color: backgroundRenderColor)
        var textures = [(GLuint, [GLfloat])]()
        if let texture = framebuffer.texture {
            textures.append((texture, standardTextureCoordinate))
        }
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), displayRenderBuffer!)

        renderQuad(withProgram: displayShader, vertices: standardImageVertices, textures: textures)
        framebuffer.release()
        OGEAGLContext.shared().presentBufferForDisplay()
    }
    
}
