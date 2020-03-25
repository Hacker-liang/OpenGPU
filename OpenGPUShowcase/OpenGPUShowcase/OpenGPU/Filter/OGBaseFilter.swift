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
    
    var maximumInputs: UInt
    
    private let shader: OGShaderProgram
    
    init(shader: OGShaderProgram, numberOfInputs: UInt = 1) {
        self.maximumInputs = numberOfInputs
        self.shader = shader
        self.targets = OGTargetContainer()
    }
    
    convenience init(vertexShader: String? = nil, fragmentShader: String, numberOfInput: UInt = 1) {
        
        let shader = OGEAGLContext.shared().programForVertext(vertexShader ?? OGShaderLanguage.vertex.vertextShaderContent(textureCount: Int(numberOfInput)), fragmentShader: fragmentShader)
        
        self.init(shader: shader, numberOfInputs: numberOfInput)
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
            self.releaseInputFramebuffers() //释放所有输入进来的framebuffer
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
    
    private func releaseInputFramebuffers() {
        for key in self.inputFrameBuffers.keys {
            self.inputFrameBuffers[key]?.release()
        }
        self.inputFrameBuffers.removeAll()
    }
}

