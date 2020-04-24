//
//  OMStickerManager.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/23.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

class OMStickerManager: NSObject {
    
    var stickerParts: [OMSticker] = []
    
    func loadSticker(with config: [String: Any]) {
        guard let partDic = config["parts"] as? [String: [String: Any]] else {
            fatalError("贴纸config配置出错")
        }
        for key in partDic.keys {
            guard let value = partDic[key] else {
                return
            }
            let sticker = OMSticker(name: key, config: value)
            stickerParts.append(sticker)
        }
    }
}
