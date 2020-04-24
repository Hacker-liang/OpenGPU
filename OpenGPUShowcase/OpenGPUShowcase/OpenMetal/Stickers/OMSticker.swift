//
//  OMSticker.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/23.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

class OMSticker: NSObject {
    
    private (set) var width: Float = 0.0
    
    private (set)  var height: Float = 0.0
    
    private (set) var texture: OMTexture?
    
    private (set) var stickerName: String?
    
    private (set) var showDuration: Float = 0.0

    private (set) var frameCount: Int = 0
    
    private (set) var loopRender: Bool = false
    
    private (set) var stickerFrameList: OMStickerFrameList<OMStickerFrame> = .end
    
    init(name: String, config: [String: Any]) {
        stickerName = name
        width = config["width"] as? Float ?? 0.0
        height = config["height"] as? Float ?? 0.0
        frameCount = config["frameCount"] as? Int ?? 0
        loopRender = config["triggerLoop"] as? Bool ?? false
        super.init()
        self.prepareStickerFrameData()
    }
    
    private func prepareStickerFrameData() {
        for index in 0..<frameCount {
            let stickerFrame = OMStickerFrame()
            stickerFrame.width = width
            stickerFrame.height = height
            stickerFrame.stickerName = String(format: "\(stickerFrame)_%03i", index)
            stickerFrameList.push(stickerFrame)
        }
    }
    
    private func uploadImage2Texture() {
        for stickerFrame in stickerFrameList {
            stickerFrame.uploadImage2Texture()
        }
    }
}
