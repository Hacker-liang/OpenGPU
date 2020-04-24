//
//  OMStickerFilter.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/23.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

class OMStickerFilter: OMBaseFilter {
    

    private var stickerTextures: [(vertex: [Float], texture: OMTexture)] = []
    
    override func newTextureAvailable(texture: OMTexture, atIndex: UInt) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture = self.outputTexture?.texture
        rpd.colorAttachments[0].loadAction = .dontCare
        rpd.colorAttachments[0].storeAction = .store
        
        guard let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd) else {
            return
        }
        
        var vertices = [Float]()
        
        for (index, item) in stickerTextures.enumerated() {
            vertices.append(contentsOf: item.vertex)
            encoder.setFragmentTexture(item.texture.texture, index: index)
        }
        if vertices.count > 0 {
            let vertexBuffer = OMRenderDevice.shared().device.makeBuffer(length: MemoryLayout<Float>.size*vertices.count, options: .storageModeShared)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        }
    }
}
