//
//  OMFaceDetect.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/15.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit

let faceDecter: OMFaceDetect = OMFaceDetect()

class OMFaceDetect: NSObject {
    
    private var faceMarkManager: MGFacepp!
    
    func shared() -> OMFaceDetect {
        return faceDecter
    }
    
    override init() {
        super.init()
        self.auth()
    }
    
    private func setupFaceApp() {
        guard let modelPath = Bundle.main.path(forResource: "megviifacepp_0_5_2_model", ofType: ""), let data = NSData.init(contentsOfFile: modelPath) else {
            fatalError("创建人脸识别失败")
        }
        
        let faceMarkManager = MGFacepp(model: data as Data, maxFaceCount: 1) { (faceConfig) in
            faceConfig?.minFaceSize = 100
            faceConfig?.interval = 40
            faceConfig?.orientation = 90
            faceConfig?.detectionMode = .trackingRobust
            faceConfig?.pixelFormatType = .PixelFormatTypeRGBA
        }
        self.faceMarkManager = faceMarkManager
    }
    
    func detectSampleBuffer(sampleBuffer: CMSampleBuffer, detectResult:((_ faces: [OMFaceModel])->Void)) {
        guard let manager = self.faceMarkManager else {
            return
        }
        let cgImage = MGImageData(sampleBuffer: sampleBuffer)
//        let frameWidth = cgImage?.width
//        let frameHeight = cgImage?.height
        manager.beginDetectionFrame()
        guard let facelist = manager.detect(with: cgImage) else {
            detectResult([])
            return
        }
        
        var tempArray = [OMFaceModel]()
        for item in facelist {
            let faceModel = OMFaceModel()
            var points = [CGPoint]()
            for p in item.points {
                points.append(p.cgPointValue)
            }
            faceModel.landmarks = points
            faceModel.faceBounds = item.rect
            faceModel.pitchAngle = CGFloat(item.pitch)
            faceModel.yawAngle = CGFloat(item.yaw)
            faceModel.rollAngle = CGFloat(item.roll)
            
            tempArray.append(faceModel)
        }
        self.faceMarkManager.endDetectionFrame()
        detectResult(tempArray)
    }
    
    func auth() {
        MGFaceLicenseHandle.license { (license, sdkDate) in
            if !license {
                print("鉴权失败")
            } else {
                self.setupFaceApp()
                print("鉴权成功")
            }
        }
    }
}


class OMFaceModel: NSObject {
    var faceBounds: CGRect?
    var landmarks: [CGPoint]?
    var yawAngle: CGFloat = 0.0
    var rollAngle: CGFloat = 0.0
    var pitchAngle: CGFloat = 0.0
}
