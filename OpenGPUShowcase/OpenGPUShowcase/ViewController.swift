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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        displayView = OMRenderView(frame: self.view.bounds)
        self.view.addSubview(displayView)
        camera = OMCamera(capturePreset: AVCaptureSession.Preset.hd1280x720, cameraPosition: .back, captureAsYUV: false)
        
        let fileter = OMBaseFilter(vertextFuncName: "oneInputVertexShader", fragmentFuncName: "commonFragmentShader")
        camera?.addTarget(target: fileter)
        
        displayView = OMRenderView(frame: self.view.bounds)
        self.view.addSubview(displayView)
        
        fileter.addTarget(target: displayView)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        camera?.startCapture()
    }
    
}

