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
    
    private (set) var processPSO: MTLRenderPipelineState!
    private (set) var commandQueue: MTLCommandQueue!

    private (set) var inputTextures = [Int: OMTexture]()
    
    private (set) var outputTexture: OMTexture?
    
    private (set) var maxTextureInputs: Int = 1
    
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
        
        inputTextures[Int(atIndex)] = texture
        
        if inputTextures.count >= maxTextureInputs {
            guard let outputWidth = inputTextures[0]?.texture?.width,
            let outputHeight = inputTextures[0]?.texture?.height else {
                return
            }
            
            let outputTexture = OMTexture(device: OMRenderDevice.shared().device, width: outputWidth, height: outputHeight, oreation: 0)
            guard let commandBuffer = commandQueue?.makeCommandBuffer() else { return }

            var arrays = [OMTexture]()
            for i in 0..<maxTextureInputs {
                if let t = inputTextures[i] {
                    arrays.append(t)
                }
            }
            commandBuffer.renderQuda(pipelineState: self.processPSO, inputTextures: arrays, outputTexture: outputTexture)
            commandBuffer.commit()
            
            self.updateAllTargets(texture: outputTexture)
        }
    }
    
    
    
}

let kOneInputVertexFunc = "oneInputVertexShader"
let kTwoputVertexFunc = "twoInputVertexShader"
let kCommonFragmentShader = "commonFragmentShader"
