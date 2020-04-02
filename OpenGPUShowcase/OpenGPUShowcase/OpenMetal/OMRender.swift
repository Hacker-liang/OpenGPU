//
//  OMRender.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/30.
//  Copyright © 2020 langren. All rights reserved.
//

import Foundation
import MetalKit

public let standardImageVertices:[Float] = [-1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0]
public let standardTextureCoordinate:[Float] = [0, 0, 1.0, 0, 0, 1.0, 1.0, 1.0]

extension MTLCommandBuffer {
        
    func renderQuda(pipelineState: MTLRenderPipelineState, renderPassDescriptor: MTLRenderPassDescriptor? = nil, inputTextures: [OMTexture], imageVertices:[Float] = standardImageVertices, outputTexture: OMTexture) {
        
        let vertextBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: imageVertices, length: imageVertices.count*MemoryLayout<Float>.size, options: .storageModeShared);
        vertextBuffer?.label = "vertices"
        
        let renderPass: MTLRenderPassDescriptor
        
        if renderPassDescriptor == nil {
            renderPass = MTLRenderPassDescriptor()
            renderPass.colorAttachments[0].texture = outputTexture.texture
            renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
            renderPass.colorAttachments[0].storeAction = .store
            renderPass.colorAttachments[0].loadAction = .clear
        
        } else {
            renderPass = renderPassDescriptor!
        }
        guard let renderEncoder = self.makeRenderCommandEncoder(descriptor: renderPass) else {
            fatalError("error create commandEncoder")
        }
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setVertexBuffer(vertextBuffer, offset: 0, index: 0)

        for (index,texture) in inputTextures.enumerated() {
            let textureCoordinateBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: standardTextureCoordinate, length: standardTextureCoordinate.count*MemoryLayout<Float>.size, options: .storageModeShared);
            textureCoordinateBuffer?.label = "texture coordinate buffer"
            renderEncoder.setVertexBuffer(textureCoordinateBuffer, offset: 0, index: index+1)
            renderEncoder.setFragmentTexture(texture.texture, index: index)
        }
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}

func generateRenderPipelineStateObject(device: OMRenderDevice, vertexFuncName: String, fragmentFuncName: String, operateName: String) -> MTLRenderPipelineState {
    
    guard let vertexFunc = device.shaderLibrary?.makeFunction(name: vertexFuncName) else {
        fatalError("error create vertexFunc with :\(vertexFuncName)")
    }
    guard let fragmentFunc = device.shaderLibrary?.makeFunction(name: fragmentFuncName) else {
        fatalError("error create fragmentFunc with :\(fragmentFuncName)")
    }
    do {
        let psd = MTLRenderPipelineDescriptor()
        psd.vertexFunction = vertexFunc
        psd.fragmentFunction = fragmentFunc
        psd.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        let pso = try device.device.makeRenderPipelineState(descriptor: psd)
        return pso
    } catch {
        fatalError("error create PSO")
    }
}
