//
//  OMRenderView.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/30.
//  Copyright © 2020 langren. All rights reserved.
//

import Foundation
import MetalKit

class OMRenderView: MTKView, OMImageConsumer {
    
    var renderPSO: MTLRenderPipelineState!
    var renderTexture: OMTexture?
    var commandQueue: MTLCommandQueue?
    
    init(frame frameRect: CGRect) {
        super.init(frame: frameRect, device: OMRenderDevice.shared().device)
        self.device = OMRenderDevice.shared().device
        self.renderPSO = generateRenderPipelineStateObject(device: OMRenderDevice.shared(), vertexFuncName: "commonVertextShader", fragmentFuncName: "commonFragmentShader", operateName: "")
        self.commandQueue = OMRenderDevice.shared().device.makeCommandQueue()
        enableSetNeedsDisplay = false
        isPaused = true
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable, let sourceTexture = renderTexture else {
            return
        }
        let displayTexture = OMTexture(texture: drawable.texture)
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else { return }
        commandBuffer.renderQuda(pipelineState: self.renderPSO, renderPassDescriptor: self.currentRenderPassDescriptor, inputTextures: [sourceTexture], outputTexture: displayTexture)
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    
    func newTextureAvailable(texture: OMTexture, atIndex: UInt) {
        guard let metalTexture = texture.texture else {
            return
        }
        self.drawableSize = CGSize(width: metalTexture.width, height: metalTexture.height)
        self.renderTexture = texture
        self.draw()
    }
}



