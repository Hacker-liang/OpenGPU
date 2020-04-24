//
//  OMStickerFrame.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/23.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

class OMStickerFrame: NSObject {
    
    var width: Float = 0.0
    
    var height: Float = 0.0
    
    var texture: OMTexture?
    
    var index: Int?
    
    var stickerName: String?
    
    var stickerSourcePath: String?
    
    var showDuration: Float = 0.0
    
    func uploadImage2Texture() {
        guard let path = stickerSourcePath, let stickerName = stickerName else {
            return
        }
        do {
            guard let mtlt = try OMTexture.uploadImage2Texture(filePath: "\(path)/\(stickerName)") else {
                return
            }
            self.texture = OMTexture(texture: mtlt)
            
        } catch OMTextureUploadError.fileDoesNotExit(filePath: path) {
             
        } catch OMTextureUploadError.metalError {
            
        } catch {
            
        }
    }
    
}
