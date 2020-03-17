//
//  OGPipeline.swift
//  MWVideoRecord
//
//  Created by langren on 2019/8/27.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation

/// 图像数据提供者，例如摄像头Camera，照片读取Picture等都会遵守该协议
protocol OGImageProvider {
    var targets: OGTargetContainer {get}
    
}

extension OGImageProvider {
    
    func addTarget(target: OGImageConsumer, atIndex index: UInt? = nil) {
        let weakConsumer = WeakImageConsumer(value: target, index: index ?? UInt(targets.count+1))
        self.targets.append(target: weakConsumer)
    }
    
    func updateTargets(withFramebuffer framebuffer: OGFramebuffer) {
        if self.targets.count == 0 {  //如果没有target要先retain再release，会将framebuffer回收。
            framebuffer.retain()
            framebuffer.release()
        } else {
            for _ in 0..<self.targets.count {
                framebuffer.retain()
            }
        }
        for consumer in self.targets {
            consumer.0.newFramebufferAvailable(framebuffer: framebuffer, fromSourceIndex: 0)
        }
    }
}

/// 图像数据消费者，例如DisplayView，文件存储等都会遵守该协议
protocol OGImageConsumer {
    
    func newFramebufferAvailable(framebuffer: OGFramebuffer, fromSourceIndex: UInt)
    
}

// It is usual appended in a list, we hope not to keep 'consumer' strong reference
class WeakImageConsumer {
    
    var consumer: OGImageConsumer?
    
//    save the index of self
    let indexOfTarget: UInt
    
    init(value: OGImageConsumer, index: UInt) {
        self.consumer = value
        self.indexOfTarget = index
    }
}

class OGTargetContainer: Sequence {
    private var targets = [WeakImageConsumer]()
    
    private var queue = DispatchQueue(label: "OGTargetContainerQueue")
    var count: Int {
        get {
            return targets.count
        }
    }
    public func makeIterator() ->  AnyIterator<(OGImageConsumer, UInt)> {
        var index = 0
        return AnyIterator {() -> (OGImageConsumer, UInt)? in
            return self.queue.sync {
                if index >= self.targets.count {
                    return nil
                }
                while (self.targets[index].consumer == nil) {
                    self.targets.remove(at: index)
                    return nil
                }
                index += 1
                return (self.targets[index-1].consumer!, self.targets[index-1].indexOfTarget)
             }
        }
    }
    
    public func removeAll() {
        self.queue.async {
            
        }
    }
    
    public func append(target: WeakImageConsumer) {
        self.targets.append(target)
    }
    
}

infix operator --> : AdditionPrecedence

@discardableResult func --><T: OGImageConsumer>(source: OGImageProvider, destination: T) -> T {
    source.addTarget(target: destination)
    return destination
}
