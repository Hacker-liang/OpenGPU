//
//  OMFaceBeautyFilter.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/16.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

let kFaceBeautyFragmentShader = "faceBeautyFragmentShader"

class OMFaceBeautyFilter: OMBaseFilter {
    
    private var landmarkBuffer: MTLBuffer?
    
    init() {
        super.init(vertextFuncName:kOneInputVertexFunc, fragmentFuncName: kFaceBeautyFragmentShader, maxTextureInputs: 1)
    }
    
    func updateFaceData(faceData: [OMFaceModel]){
        guard faceData.count > 0 else {
            return
        }
        
        let faceModel = faceData.first!
        
        guard let faceMarks = faceModel.landmarks else {
            return
        }
        
        var marks = [Float]()
        for i in 0..<faceMarks.count {
            marks.append(Float(faceMarks[i].x))
            marks.append(Float(faceMarks[i].y))
        }
        
        landmarkBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: marks, length: MemoryLayout<Float>.size*marks.count, options: .storageModeShared)
    }
    
    override func newTextureAvailable(texture: OMTexture, atIndex: UInt) {
        guard let renderCommandBuffer = self.commandQueue.makeCommandBuffer() else {
            return
        }
        
        guard let outputWidth = texture.texture?.width, let outputHeight = texture.texture?.height else {
            return
        }
    
        let outputTexture = OMTexture(device: OMRenderDevice.shared().device, width: outputWidth, height: outputHeight, oreation: 0)
        
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = outputTexture.texture
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].loadAction = .clear
        guard let commandEncoder = renderCommandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
            fatalError("error create commandEncoder")
        }
        
        commandEncoder.setRenderPipelineState(self.processPSO)
        let vertexBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: standardImageVertices, length: standardImageVertices.count*MemoryLayout<Float>.size, options: .storageModeShared);
        vertexBuffer?.label = "vertex buffer"
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let textureCoordinateBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: standardTextureCoordinate, length: standardTextureCoordinate.count*MemoryLayout<Float>.size, options: .storageModeShared);
        textureCoordinateBuffer?.label = "texture coordinate buffer"
        commandEncoder.setVertexBuffer(textureCoordinateBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentTexture(texture.texture, index: 0)
        
        if let buffer = self.landmarkBuffer {
            let faceEnable = OMRenderDevice.shared().device.makeBuffer(bytes: [1.0], length: MemoryLayout<Float>.size, options: .storageModeShared);
            commandEncoder.label = "face landmarks buffer"
            commandEncoder.setFragmentBuffer(faceEnable, offset: 0, index: 0)
            commandEncoder.setFragmentBuffer(buffer, offset: 0, index: 1)
            
            
        } else {
            let faceEnable = OMRenderDevice.shared().device.makeBuffer(bytes: [0.0], length: MemoryLayout<Float>.size, options: .storageModeShared);
            
            var p = [Float]()
            
            for _ in 0...161 {
                p.append(0.0)
            }
            let test = OMRenderDevice.shared().device.makeBuffer(bytes: p, length: p.count*MemoryLayout<Float>.size, options: .storageModeShared);
            commandEncoder.setFragmentBuffer(faceEnable, offset: 0, index: 0)

            commandEncoder.setFragmentBuffer(test, offset: 0, index: 1)
        }
        
        
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()

        renderCommandBuffer.commit()
        
        self.updateAllTargets(texture: outputTexture)
    }
}
