//
//  OMBaseFilter.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/31.
//  Copyright © 2020 langren. All rights reserved.
//

import Foundation
import MetalKit

class OMBaseFilter: OMImageConsumer, OMImageProvider {
    
    var allTargets = [OMImageConsumer]()
    
    private var processPSO: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue!
    private var commandBuffer: MTLCommandBuffer!

    private var inputTextures = [UInt: OMTexture]()
    
    private var outputTexture: OMTexture?
    
    private var maxTextureInputs: Int = 1
    
    private var renderSemaphore = DispatchSemaphore(value: 1)
    
    init?(vertextFuncName: String, fragmentFuncName: String, maxTextureInputs: Int = 1) {
        
        guard let library = OMRenderDevice.shared().device.makeDefaultLibrary() else {
            return nil
        }
        guard let vertexFunc = library.makeFunction(name: vertextFuncName) else {
            return nil
        }
        guard let fragmentFunc = library.makeFunction(name: fragmentFuncName) else {
            return nil
        }
        
        guard let cq = OMRenderDevice.shared().device.makeCommandQueue() else {
            return nil
        }
        
        commandQueue = cq
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return nil
        }
        self.commandBuffer = commandBuffer
        
        self.maxTextureInputs = maxTextureInputs
        
        commandQueue = cq;
        
        let psd = MTLRenderPipelineDescriptor()
        psd.vertexFunction = vertexFunc
        psd.fragmentFunction = fragmentFunc
        psd.label = "basefilter_pso"
        guard let pso = try? OMRenderDevice.shared().device.makeRenderPipelineState(descriptor: psd) else {
            return nil
        }
        processPSO = pso
    }

    func addTarget(target: OMImageConsumer) {
        self.allTargets.append(target)
    }
    
    func newTextureAvailable(texture: OMTexture, atIndex: UInt) {
        let _ = renderSemaphore.wait(timeout: .distantFuture)
        defer {
            renderSemaphore.signal()
        }
        
        inputTextures[atIndex] = texture
        
        if inputTextures.count >= maxTextureInputs {
            guard let outputWidth = inputTextures[0]?.texture?.width,
            let outputHeight = inputTextures[0]?.texture?.height else {
                return
            }
            let outputTexture = OMTexture(device: OMRenderDevice.shared().device, width: outputWidth, height: outputHeight, oreation: 0)
            self.commandBuffer.renderQuda(pipelineState: self.processPSO, inputTextures: Array(inputTextures.values), outputTexture: outputTexture)
        }
    }
    
}
