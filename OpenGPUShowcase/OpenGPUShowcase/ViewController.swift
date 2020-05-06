//
//  ViewController.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/12.
//  Copyright © 2020 langren. All rights reserved.
//

import UIKit
import AVFoundation

fileprivate let FragmentShader = """

varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
void main()
{
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
}

"""

class ViewController: UIViewController {
    
    private var camera: OMCamera?
    private var displayView: OMRenderView!
    
    private var faceDetecter: OMFaceDetect?
    
    private var faceFilter: OMFaceBeautyFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
//        displayView = OMRenderView(frame: CGRect(x: 0, y: 100, width: self.view.bounds.size.width, height: self.view.bounds.size.width/9*16))
//        self.view.addSubview(displayView)
        camera = OMCamera(capturePreset: AVCaptureSession.Preset.hd1280x720, cameraPosition: .front, captureAsYUV: false)
        
        camera?.delegate = self
        
//        var last: OMImageProvider = camera!
//        for _ in 0...0 {
//            let fileter = OMLookupFilter(lookupImage: "bai.png")
//            last.addTarget(target: fileter)
//            last = fileter
//        }
        
//        faceFilter = OMFaceBeautyFilter()
//
//        last.addTarget(target: faceFilter)
//
//        faceDetecter = OMFaceDetect()
        
        let stickerFilter = OMStickerFilter()
        
        camera?.addTarget(target: stickerFilter)
        
        
        displayView = OMRenderView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.width/9*16))
        self.view.addSubview(displayView)
        
        stickerFilter.addTarget(target: displayView)
        
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        camera?.startCapture()
    }
    
}

extension ViewController: OMCameraDelegate {
    func cameraImageOutput(didOutput sampleBuffer: CMSampleBuffer) {
//        faceDetecter?.detectSampleBuffer(sampleBuffer: sampleBuffer) { [weak self] (faceList) in
//            self?.faceFilter.updateFaceData(faceData: faceList)
//        }
    }
}

