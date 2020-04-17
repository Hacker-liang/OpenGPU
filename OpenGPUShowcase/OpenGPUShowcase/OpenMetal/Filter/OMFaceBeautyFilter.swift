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
    
    private var faceThinIntensityBuffer: MTLBuffer?

    private var textureResolutionBuffer: MTLBuffer?
    
    init() {
        
        super.init(vertextFuncName:kOneInputVertexFunc, fragmentFuncName: kFaceBeautyFragmentShader, maxTextureInputs: 1)
        
        let values: [Float] = [0.05, 0.2, 0.05];
        faceThinIntensityBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: values, length: MemoryLayout<Float>.size*values.count, options: .storageModeShared)
        
        let marks: [Float] = Array(repeatElement(0.0, count: 80));
        landmarkBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: marks, length: MemoryLayout<Float>.size*marks.count, options: .storageModeShared)
        
    }
    
    func updateFaceData(faceData: [OMFaceModel]){
        guard faceData.count > 0 else {
            let values: [Float] = Array(repeatElement(0.0, count: 80));
            landmarkBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: values, length: MemoryLayout<Float>.size*values.count, options: .storageModeShared)

            return
        }
        
        let faceModel = faceData.first!
        
        guard let faceMarks = faceModel.landmarks else {
            return
        }
        
        let faceThinLandmarks = [3,44, 29,44, 7,45, 25,45, 10,46, 22,46, 14,49, 18,49, 16,49];
        
        var faceThinPoints = [Float]()
        for i in 0..<9 {
            let location = faceThinLandmarks[2*i]
            let targetLocation = faceThinLandmarks[2*i+1]
            if faceMarks.count > 2*i+1 {
                let l_point = faceMarks[location]
                let r_point = faceMarks[targetLocation]
                
                faceThinPoints.append(Float(l_point.x))
                faceThinPoints.append(Float(l_point.y))
                faceThinPoints.append(Float(r_point.x))
                faceThinPoints.append(Float(r_point.y))
            }
        }
        
        let eyeBitPoints = [74,72, 77,75];
        for i in 0...1 {
            let location = eyeBitPoints[2*i]
            let targetLocation = eyeBitPoints[2*i+1]
            if faceMarks.count > 2*i+1 {
                let l_point = faceMarks[location]
                let r_point = faceMarks[targetLocation]
                faceThinPoints.append(Float(l_point.x))
                faceThinPoints.append(Float(l_point.y))
                faceThinPoints.append(Float(r_point.x))
                faceThinPoints.append(Float(r_point.y))
            }
        }
        
        let noseThinPoints = [80,45, 81,45, 82,46, 83,46];
        for i in 0...3 {
            let location = noseThinPoints[2*i]
            let targetLocation = noseThinPoints[2*i+1]
            if faceMarks.count > 2*i+1 {
                let l_point = faceMarks[location]
                let r_point = faceMarks[targetLocation]
                faceThinPoints.append(Float(l_point.x))
                faceThinPoints.append(Float(l_point.y))
                faceThinPoints.append(Float(r_point.x))
                faceThinPoints.append(Float(r_point.y))
            }
        }
        
        landmarkBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: faceThinPoints, length: MemoryLayout<Float>.size*faceThinPoints.count, options: .storageModeShared)
    }
    
    override func newTextureAvailable(texture: OMTexture, atIndex: UInt) {
        guard let renderCommandBuffer = self.commandQueue.makeCommandBuffer() else {
            return
        }
        
        guard let outputWidth = texture.texture?.width, let outputHeight = texture.texture?.height else {
            return
        }
        
        if textureResolutionBuffer == nil {
            let resolutions: [Float] = [Float(outputWidth), Float(outputHeight)];
            textureResolutionBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: resolutions, length: MemoryLayout<Float>.size*resolutions.count, options: .storageModeShared)
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
        
//        texture2d<half> texture [[texture(0)]],
//        const device bool *faceEnable [[buffer(0)]],
//        const device FaceLandmarks *landmarks [[buffer(1)]],
//        const device FaceIntensity *faceIntensity [[buffer(2)]],
//        const device TextureResolution *resolution [[buffer(3)]]
        commandEncoder.label = "face landmarks buffer"

        let faceEnable = OMRenderDevice.shared().device.makeBuffer(bytes: [landmarkBuffer != nil], length: MemoryLayout<Bool>.size, options: .storageModeShared);
        faceEnable?.label = "face enable?"
        
        commandEncoder.setFragmentBuffer(landmarkBuffer, offset: 0, index: 1)
        
        commandEncoder.setFragmentBuffer(faceThinIntensityBuffer, offset: 0, index: 2)
        commandEncoder.setFragmentBuffer(textureResolutionBuffer, offset: 0, index: 3)
        
        commandEncoder.setFragmentBuffer(faceEnable, offset: 0, index: 4)

        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()

        renderCommandBuffer.commit()
        
        self.updateAllTargets(texture: outputTexture)
    }
}
