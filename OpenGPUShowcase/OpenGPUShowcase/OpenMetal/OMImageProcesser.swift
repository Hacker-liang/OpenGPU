//
//  OMImageProcesser.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/9.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit
import MetalKit

class OMImageProcesser: OMImageProvider {
    
    private var imageTexture: OMTexture?
    
    private var imageBitmap: CGImage?
    
    init(image: String) {
        allTargets = [OMImageConsumer]()
    }
    
    var allTargets: [OMImageConsumer]
    
    func addTarget(target: OMImageConsumer) {
        self.allTargets.append(target)
    }
    
    public func processImage() {
        guard let image = imageBitmap else { return }
        let textureLoader = MTKTextureLoader(device: OMRenderDevice.shared().device)
        textureLoader.newTexture(cgImage: image, options: [MTKTextureLoader.Option.SRGB: false], completionHandler: { (texture, error) in
            if let t = texture {
                self.imageTexture = OMTexture(texture: t)
            }
        })
    }
    
}
