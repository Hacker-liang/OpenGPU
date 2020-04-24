//
//  OMFaceBeautyFilter.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/16.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

let kFaceBeautyFragmentShader = "faceBeautyFragmentShader"
let kFaceBeautyFragmentShader_v2 = "faceBeautyFragmentShader_v2"

let kCoordinateOffsetComputeFunc = "coordinateOffsetComputeFunc"

class OMFaceBeautyFilter: OMBaseFilter {
    
    private var landmarkBuffer: MTLBuffer?
    
    private var faceThinIntensityBuffer: MTLBuffer?

    private var textureResolutionBuffer: MTLBuffer?
    
    private var coordinateOffsetBuffer: MTLBuffer?
    
    private var calculatedFaceTrackId: Int?  //已经计算的facetrackid
    
    init() {
        
        super.init(vertextFuncName:kOneInputVertexFunc, fragmentFuncName: kFaceBeautyFragmentShader, maxTextureInputs: 1)
        
        let values: [Float] = [0.05, 0.2, 0.05];
        faceThinIntensityBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: values, length: MemoryLayout<Float>.size*values.count, options: .storageModeShared)
        
        let marks: [Float] = Array(repeatElement(0.0, count: 80));
        landmarkBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: marks, length: MemoryLayout<Float>.size*marks.count, options: .storageModeShared)
        
    }
    
    lazy private var calculatorOffsetPSO: MTLComputePipelineState? = {
       
        guard let computeFunc = OMRenderDevice.shared().shaderLibrary?.makeFunction(name: kCoordinateOffsetComputeFunc) else {
            return nil
        }
        return try? OMRenderDevice.shared().device.makeComputePipelineState(function: computeFunc)
    }()
    
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
        var faceThinPoint2Calculator = [Float]()
        
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
                
                faceThinPoint2Calculator.append(Float(l_point.x))
                faceThinPoint2Calculator.append(Float(l_point.y))
                faceThinPoint2Calculator.append(Float(r_point.x))
                faceThinPoint2Calculator.append(Float(r_point.y))
                
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
        
        if calculatedFaceTrackId == nil {
            calculatedFaceTrackId = faceModel.trackId
            self.calculateCoordinateOffset(points: faceThinPoint2Calculator)
        }
        
        landmarkBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: faceThinPoints, length: MemoryLayout<Float>.size*faceThinPoints.count, options: .storageModeShared)
    }
    
    private func calculateCoordinateOffset(points: [Float]) {
        guard let commandBuffer = self.commandQueue.makeCommandBuffer(), let pso = self.calculatorOffsetPSO else {
            return
        }
        
    
//        let input1Buffer = device.makeBuffer(bytes: Array(points[0...1]), length: MemoryLayout<Float>.size*2, options: .storageModeShared)
//        let input2Buffer = device.makeBuffer(bytes: Array(points[2...3]), length: MemoryLayout<Float>.size*2, options: .storageModeShared)
//        let input3Buffer = device.makeBuffer(bytes: [Float(720), Float(1280)], length: MemoryLayout<Float>.size*2, options: .storageModeShared)
//        let input4Buffer = device.makeBuffer(bytes: [Float(0.1)], length: MemoryLayout<Float>.size, options: .storageModeShared)
//        computeEncoder?.setBuffer(input1Buffer, offset: 0, index: 0)
//        computeEncoder?.setBuffer(input2Buffer, offset: 0, index: 1)
//        computeEncoder?.setBuffer(input3Buffer, offset: 0, index: 2)
//        computeEncoder?.setBuffer(input4Buffer, offset: 0, index: 3)
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()
                        
        computeEncoder?.setComputePipelineState(pso)

        let device = OMRenderDevice.shared().device
        coordinateOffsetBuffer = device.makeBuffer(length: MemoryLayout<Float>.size*2*100*9, options: .storageModeShared)

        computeEncoder?.setBytes(points, length: MemoryLayout<Float>.size*4*9, index: 0)
        
        computeEncoder?.setBytes([Float(720), Float(1280)], length: MemoryLayout<Float>.size*2, index: 1)
        computeEncoder?.setBytes([Float(0.1)], length: MemoryLayout<Float>.size*1, index: 2)

        computeEncoder?.setBuffer(coordinateOffsetBuffer, offset: 0, index: 3)

        let threadGroupSize = pso.maxTotalThreadsPerThreadgroup;

        let threadgroupSize = MTLSizeMake(1, 1, 1);

        computeEncoder?.dispatchThreadgroups(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
//        computeEncoder?.dispatchThreads(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: threadgroupSize)
        //
        computeEncoder?.endEncoding()
        commandBuffer.commit()

        commandBuffer.waitUntilCompleted()
        
//        var pointer: UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float>.size*200, alignment: MemoryLayout<Float>.alignment)
//        
//        for i in 0..<200 {
//            pointer.advanced(by: i*MemoryLayout<Float>.size).storeBytes(of: 0.1*Float(i), as: Float.self)
//        }

        for i in stride(from: 200, to: 400, by: 2) {

            print("coordinate offset：x:\(String(describing: self.coordinateOffsetBuffer?.contents().advanced(by: i*MemoryLayout<Float>.size).load(as: Float.self)))  y:\(String(describing: self.coordinateOffsetBuffer?.contents().advanced(by: (i+1)*MemoryLayout<Float>.size).load(as: Float.self)))")
        }

//        commandBuffer.addCompletedHandler { (commandbuffer) in
//
//            print("coordinate offset：\(self.coordinateOffsetBuffer?.contents())")
//
//        }
    }
    

    
    override func newTextureAvailable(texture: OMTexture, atIndex: UInt) {
        
        if self.coordinateOffsetBuffer == nil {  //如果没有识别到人脸，直接将纹理传递下去
            self.updateAllTargets(texture: texture)
            return
        }
        
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
        commandEncoder.setFragmentBuffer(coordinateOffsetBuffer, offset: 0, index: 5)

        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()

        renderCommandBuffer.commit()
        
        self.updateAllTargets(texture: outputTexture)
    }
}
