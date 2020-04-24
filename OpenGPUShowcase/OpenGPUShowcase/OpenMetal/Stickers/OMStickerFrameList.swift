//
//  OMStickerFrameList.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/23.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

enum OMStickerFrameList<Element> {
    case end
    indirect case node(value: Element, next: OMStickerFrameList)
}

extension OMStickerFrameList {
    func cons(_ x: Element) -> OMStickerFrameList {
        return .node(value: x, next: self)
    }
    
    mutating func push(_ x: Element) {
        self = cons(x)
    }
    
    mutating func pop() -> Element? {
        switch self {
        case .end:
            return nil
        case let .node(value, next: tail):
            self = tail
            return value
        }
    }
}

extension OMStickerFrameList: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = Element
    init(arrayLiteral elements: Element...) {
        self = elements.reversed().reduce(.end){ (list, element) in
            list.cons(element)
        }
    }
}

extension OMStickerFrameList: IteratorProtocol, Sequence {
    mutating func next() -> Element? {
        return pop()
    }
}
