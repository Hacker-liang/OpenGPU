//
//  OMDevice.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/30.
//  Copyright © 2020 langren. All rights reserved.
//

import Foundation
import MetalKit

private let sharedDevice = OMRenderDevice()

public class OMRenderDevice {
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let shaderLibrary: MTLLibrary?
    
    class func shared() -> OMRenderDevice {
        return sharedDevice
    }
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {fatalError("error create metal device")}
        self.device = device
        guard let queue = device.makeCommandQueue() else {fatalError("error create commandQueue")}
        self.commandQueue = queue
        shaderLibrary = device.makeDefaultLibrary()
    }
}
