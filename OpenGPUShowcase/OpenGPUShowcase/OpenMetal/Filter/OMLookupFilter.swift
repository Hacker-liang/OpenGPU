//
//  OMLookupFilter.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/8.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

class OMLookupFilter: OMBaseFilter {
    
    private var lookupImageProcesser: OMImageProcesser?
    
    init(lookupImage: String) {
        super.init(vertextFuncName: kTwoputVertexFunc, fragmentFuncName: kLookupFragmentFunc, maxTextureInputs: 2)
        lookupImageProcesser = OMImageProcesser(image: lookupImage)
        lookupImageProcesser?.addTarget(target: self)
        lookupImageProcesser?.processImage()
    }
    
//    override func addTarget(target: OMImageConsumer) {
//        self.lookupImageProcesser?.addTarget(target: target)
//    }
//    
//    override func newTextureAvailable(texture: OMTexture, atIndex: UInt) {
//        super.newTextureAvailable(texture: texture, atIndex: 0)
//    }
}

let kLookupFragmentFunc = "lookupFragmentFunc"

