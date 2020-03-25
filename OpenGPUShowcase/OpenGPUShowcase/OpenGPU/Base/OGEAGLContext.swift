//
//  OGEAGLContext.swift
//  MWVideoRecord
//
//  Created by langren on 2019/8/30.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation
import OpenGLES
import AVFoundation

fileprivate let sharedImageProcessingContext = OGEAGLContext()

fileprivate let ContextQueueTag = 88

class OGEAGLContext {

    public class func shared() -> OGEAGLContext {
        return sharedImageProcessingContext
    }
    
    //当前context所在的线程
    private let serialDispatchQueue:DispatchQueue = DispatchQueue(label:"com.iqiyi.openGPU", attributes: [])
    private let dispatchQueueKey = DispatchSpecificKey<Int>()
    
    let context: EAGLContext!
    
    private var shaderProgramCache = [String: OGShaderProgram]()
    
    lazy var framebufferCache: OGFramebufferCache = {
        return OGFramebufferCache(context: self)
    }()
    
    lazy var coreVideoTextureCache:CVOpenGLESTextureCache = {
        var newTextureCache:CVOpenGLESTextureCache? = nil
        let err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, self.context, nil, &newTextureCache)
        return newTextureCache!
    }()
    
    init() {
        serialDispatchQueue.setSpecific(key: dispatchQueueKey, value: ContextQueueTag)
        
        guard let tempContext = EAGLContext(api: .openGLES2) else {
            fatalError("创建opengl上下文失败")
        }
        context = tempContext
        EAGLContext.setCurrent(context)
        glDisable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_TEXTURE_2D))
    }
}

extension OGEAGLContext {
    public func programForVertext(_ vertextShader: String, fragmentShader: String) -> OGShaderProgram {
        let key = "V: \(vertextShader) F: \(fragmentShader)"
        if let shader = shaderProgramCache[key] {
            return shader
        }
        
        return runOperationSynchronously {
            let shaderProgram = OGShaderProgram(vertexShaderString: vertextShader, fragmentShaderString: fragmentShader)
            self.shaderProgramCache[key] = shaderProgram
            return shaderProgram
        }
    }
}

//MARK: Public
extension OGEAGLContext {
    
    //切换为当前上下文
    public func makeCurrentContext() {
        if EAGLContext.current() != self.context {
            EAGLContext.setCurrent(self.context)
        }
    }
    
    //rbo rendering
    public func presentBufferForDisplay() {
        self.context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
}

//MARK: queue
extension OGEAGLContext {
    
    //切换到当前context所在的线程，并异步执行
    func runOperationAsynchronously(_ operation: @escaping ()->()) {
        self.serialDispatchQueue.async {
            self.makeCurrentContext()
            operation()
        }
    }
    
    //切换到当前context所在的线程，并同步执行
    func runOperationSynchronously(_ operation: @escaping ()->()) {
        if DispatchQueue.getSpecific(key: dispatchQueueKey) == ContextQueueTag { //如果已经在gpu线程，没必要再切了
            operation()
        } else {
            self.serialDispatchQueue.sync {
                self.makeCurrentContext()
                operation()
            }
        }
    }
    
    func runOperationSynchronously<T>(_ operation: @escaping ()->T) -> T {
        var returnedValue: T!
        runOperationSynchronously {
            returnedValue = operation()
        }
        return returnedValue
    }
}
