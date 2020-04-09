//
//  OMLookupFilter.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/8.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

class OMLookupFilter: OMBaseFilter {
    init(lookupImage: String) {
        
        super.init(vertextFuncName: kOneInputVertexFunc, fragmentFuncName: kLookupFragmentFunc, maxTextureInputs: 2)
    }
    
    
    override func newTextureAvailable(texture: OMTexture, atIndex: UInt) {
        
    }

}

let kLookupFragmentFunc = "lookupFragmentFunc"

