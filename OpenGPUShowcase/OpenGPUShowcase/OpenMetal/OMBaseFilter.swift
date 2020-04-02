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

    private var inputTextures = [UInt: OMTexture]()
    
    private var outputTexture: OMTexture?
    
    private var maxTextureInputs: Int = 1
    
    private var renderSemaphore = DispatchSemaphore(value: 1)
    
    init(vertextFuncName: String, fragmentFuncName: String, maxTextureInputs: Int = 1) {
        
        processPSO = generateRenderPipelineStateObject(device: OMRenderDevice.shared(), vertexFuncName: vertextFuncName, fragmentFuncName: fragmentFuncName, operateName: "")
        
        guard let cq = OMRenderDevice.shared().device.makeCommandQueue() else {
            fatalError("error create commandQueue")
        }
        
        commandQueue = cq
        
        self.maxTextureInputs = maxTextureInputs
        
        commandQueue = cq;

    }

    func addTarget(target: OMImageConsumer) {
        self.allTargets.append(target)
    }
    
    func newTextureAvailable(texture: OMTexture, atIndex: UInt) {
//        let _ = renderSemaphore.wait(timeout: .distantFuture)
//        defer {
//            renderSemaphore.signal()
//        }
        
        inputTextures[atIndex] = texture
        
        if inputTextures.count >= maxTextureInputs {
            guard let outputWidth = inputTextures[0]?.texture?.width,
            let outputHeight = inputTextures[0]?.texture?.height else {
                return
            }
            
            let outputTexture = OMTexture(device: OMRenderDevice.shared().device, width: outputWidth, height: outputHeight, oreation: 0)
            guard let commandBuffer = commandQueue?.makeCommandBuffer() else { return }

            commandBuffer.renderQuda(pipelineState: self.processPSO, inputTextures: Array(inputTextures.values), outputTexture: outputTexture)
            commandBuffer.commit()
            
            self.updateAllTargets(texture: outputTexture)
        }
    }
    
}
