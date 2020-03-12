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
    var targetContainer: OGTargetContainer {get}
}

extension OGImageProvider {
    func addTarget(target: OGImageConsumer, atIndex: Int? = nil) {
        if let index = atIndex {
            if index > 0 && index <= self.targetContainer.targets.count {
                self.targetContainer.targets.insert(WeakImageConsumer(value: target, index: UInt(index)), at: index)
            }
        } else {
            self.targetContainer.targets.append(WeakImageConsumer(value: target, index: UInt(self.targetContainer.targets.count)))
        }
    }
    
    func updateTargets(withFramebuffer framebuffer: OGFramebuffer) {
        if self.targetContainer.targets.count == 0 {  //如果没有target要先retain再release，会将framebuffer回收。
            framebuffer.retain()
            framebuffer.release()
        } else {
            for _ in self.targetContainer.targets {
                framebuffer.retain()
            }
        }
        for (index, weakConsumer) in self.targetContainer.targets.enumerated() {
            weakConsumer.consumer?.newFramebufferAvailable(framebuffer: framebuffer, fromSourceIndex: uint(index))
        }
    }
}

/// 图像数据消费者，例如DisplayView，文件存储等都会遵守该协议
protocol OGImageConsumer {
    
    func newFramebufferAvailable(framebuffer: OGFramebuffer, fromSourceIndex: uint)
    
}

class WeakImageConsumer {
    var consumer: OGImageConsumer?
    let index: UInt
    init(value: OGImageConsumer, index: UInt) {
        self.consumer = value
        self.index = index
    }
}

class OGTargetContainer: Sequence {
    var targets = [WeakImageConsumer]()
    
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
                return (self.targets[index-1].consumer!, self.targets[index-1].index)
             }
        }
    }
    
    public func removeAll() {
        self.queue.async {
            
        }
    }
    
}

infix operator --> : AdditionPrecedence

@discardableResult func --><T: OGImageConsumer>(source: OGImageProvider, destination: T) -> T {
    source.addTarget(target: destination)
    return destination
}
