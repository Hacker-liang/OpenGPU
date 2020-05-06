//
//  OMStickerFilter.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/23.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

let kStickerVertexFunc = "stickerVertexShader"
let kStickerFragmentFunc = "stickerFragmentShader"

class OMStickerFilter: OMBaseFilter {
    

    private var stickerTextures: [(vertex: [Float], texture: OMTexture)] = []
    public let standardImageVertices:[Float] = [-1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0]

    let vertex: [[Float]] = [[-1.0, 1.0, -0.3, 1.0, -1.0, 0.3, -0.3, 0.3]]
    func testData() {
        var testData = [(vertex: [Float], texture: OMTexture)]()
        for i in 0...3 {
            let path = Bundle.main.path(forResource: "heart_000", ofType: "png")
            let texture = OMTexture(texture: try! OMTexture.uploadImage2Texture(filePath: path!)!)
            
            
            let item = (vertex.first!, texture)
            testData.append(item)
        }
        stickerTextures = testData
    }
    
    convenience init() {
        self.init(vertextFuncName: kStickerVertexFunc, fragmentFuncName: kStickerFragmentFunc)
        self.testData()
    }
    
    override func newTextureAvailable(texture: OMTexture, atIndex: UInt) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        guard let outputWidth = texture.texture?.width, let outputHeight = texture.texture?.height else {
            return
        }
        let outputTexture = OMTexture(device: OMRenderDevice.shared().device, width: outputWidth, height: outputHeight, oreation: 0)
        
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture = outputTexture.texture
        rpd.colorAttachments[0].loadAction = .dontCare
        rpd.colorAttachments[0].storeAction = .store
        rpd.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        guard let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd) else {
            return
        }
        
        var vertices = [Float]()
        var textures = [MTLTexture]()

        if let value = texture.texture {
            textures.append(value)
        }

        vertices.append(contentsOf: standardImageVertices)

        for item in stickerTextures {
            vertices.append(contentsOf: item.vertex)

            if let value = item.texture.texture {
                textures.append(value)
            }
        }
        if vertices.count > 0 {
            let vertexBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: vertices, length: MemoryLayout<Float>.size*vertices.count, options: .storageModeShared)

            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            let coordinateBuffer = OMRenderDevice.shared().device.makeBuffer(bytes: standardTextureCoordinate, length: MemoryLayout<Float>.size*standardTextureCoordinate.count, options: .storageModeShared)

            encoder.setVertexBuffer(coordinateBuffer, offset: 0, index: 1)
            
            encoder.setVertexBytes([5], length: 8, index: 2)
            encoder.setFragmentTextures(textures, range: 0..<textures.count)
        }
        encoder.setRenderPipelineState(self.processPSO)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count/2)

        encoder.endEncoding()
        
        commandBuffer?.commit()
        
        updateAllTargets(texture: outputTexture)
    }
}
