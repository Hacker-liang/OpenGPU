//
//  OGBaseFilter.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/17.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

class OGBaseFilter: OGImageConsumer, OGImageProvider {
    
    public var backgroundColor = OGColor.red

    var inputFrameBuffers = [UInt: OGFramebuffer]()
    var outputFrameBuffer: OGFramebuffer!
    
    private let maximumInputs: UInt
    private let shader: OGShaderProgram
    
    
    init(shader: OGShaderProgram, numberOfInputs: UInt = 1) {
        self.maximumInputs = numberOfInputs
        self.shader = shader
    }
    
    init(vertexShader: String? = nil, fragmentShader: String, numberOfInput: UInt = 1) {
        
        self.shader = OGShaderProgram(vertexShaderString: vertexShader ?? OGShaderLanguage.vertex.shaderContent(), fragmentShaderString: fragmentShader)
        
        self.maximumInputs = numberOfInput
    }
    
    var targets: OGTargetContainer = OGTargetContainer()
    
    func newFramebufferAvailable(framebuffer: OGFramebuffer, fromSourceIndex: UInt) {
        if let previousFramebuffer = self.inputFrameBuffers[fromSourceIndex] {
            previousFramebuffer.release()
        }
        self.inputFrameBuffers[fromSourceIndex] = framebuffer
        
        if (UInt(self.inputFrameBuffers.count) == self.maximumInputs) {  //所有的纹理都已经就位
            self.renderFrame()
            self.updateTargets(withFramebuffer: self.outputFrameBuffer)
        }
        
    }
    
    private func renderFrame() {
        self.outputFrameBuffer = OGEAGLContext.shared().framebufferCache.requestFrameBuffer(orentation: .portrait, size: self.inputFrameBuffers[0]?.size ?? CGSize.zero)
        
        self.outputFrameBuffer.activateFramebuffer()
        
        clearFramebufferColor(color: self.backgroundColor)
        
        var texteures = [(GLuint, [GLfloat])]()
        
        for f in self.inputFrameBuffers.values where f.texture != nil {
            texteures.append((f.texture!, kStandardTextureCoordinate))
        }
        renderQuad(withProgram: self.shader, vertices: kStandardImageVertices, textures: texteures)
    }
}

