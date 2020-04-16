//
//  OMCamera.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/30.
//  Copyright © 2020 langren. All rights reserved.
//

import Foundation
import AVFoundation

protocol OMCameraDelegate: NSObject {
    
    func cameraImageOutput(didOutput sampleBuffer: CMSampleBuffer)
    
}

class OMCamera: NSObject, OMImageProvider {
    
    let captureAsYUV: Bool  //是否以YUV的格式进行视频捕获
    
    public weak var delegate: OMCameraDelegate?

    private var captureSession: AVCaptureSession!
    private var captureDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var cameraPosition: AVCaptureDevice.Position!
    private var capturePreset: AVCaptureSession.Preset!
    private var textureCache: CVMetalTextureCache!
    
    private var cameraProcessQueue: DispatchQueue?  //视频处理队列
    
    init(capturePreset: AVCaptureSession.Preset, cameraPosition :AVCaptureDevice.Position = .back, captureAsYUV: Bool = true) {
        self.capturePreset = capturePreset
        self.captureAsYUV = captureAsYUV
        self.cameraPosition = cameraPosition
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, OMRenderDevice.shared().device, nil, &textureCache)
        super.init()
        self.configCamera()
    }
    
    private func configCamera() {
        self.captureSession = AVCaptureSession()
        
        //开始配置session
        self.captureSession.beginConfiguration()
        self.captureDevice = self.deviceWithCameraPosition(position: self.cameraPosition)
        guard let device = self.captureDevice else {
            return
        }
        do {
            try self.videoInput = AVCaptureDeviceInput(device: device)
        } catch {
            captureDevice = nil
        }
        guard let input = self.videoInput, captureSession.canAddInput(input) else {
            return
        }
        captureSession.addInput(input)
        
        videoOutput = AVCaptureVideoDataOutput()
        
        //我们不希望在回调里处理视频信息的时候当前帧被销毁，因此将此值设为false
        videoOutput?.alwaysDiscardsLateVideoFrames = false
        
        if self.captureAsYUV {
            //设置数据采集格式为YUV,并且摄像头默认采集格式是FULL RANGE
            //这里也可以设置成别的格式，但是请注意，不同的格式，后续YUV到RGB的转换矩阵是不一样的。
            videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: (kCVPixelFormatType_420YpCbCr8BiPlanarFullRange))]
        } else {
            //设置数据采集格式为BGRA，注意不是RGBA
            videoOutput?.videoSettings =  [kCVPixelBufferPixelFormatTypeKey as String:NSNumber(value:Int32(kCVPixelFormatType_32BGRA))]
        }
        guard let output = self.videoOutput, captureSession.canAddOutput(output) else {
            return
        }
        captureSession.addOutput(output)
        captureSession.sessionPreset = self.capturePreset
        self.cameraProcessQueue = DispatchQueue.global(qos: .default)
        videoOutput?.setSampleBufferDelegate(self, queue: self.cameraProcessQueue)
        
        for connection in output.connections {
            for port in connection.inputPorts {
                if port.mediaType == AVMediaType.video {
                    //这里我们设置为竖屏捕获，如果想要横屏显示，在OpenGL渲染的时候旋转一下。
                    connection.videoOrientation = .portrait
                    //如果是前置摄像头的话，我们默认镜像捕获
                    connection.isVideoMirrored = self.cameraPosition == .front
                }
            }
        }
        //提交session配置，让刚才做的这么一大堆事情生效
        captureSession.commitConfiguration()
        
    }
    
    private func deviceWithCameraPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
//        let session: AVCaptureDevice.DiscoverySession
//
//        if #available(iOS 13.0, *) {
////            session = AVCaptureDevice.default(deviceTypes: [AVCaptureDevice.DeviceType.builtInDualCamera], mediaType: .video, position: position)
//        } else {
////            session = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInDualCamera], mediaType: .video, position: position)
//        }
        
//        guard let device = session.devices.first else {
//            return AVCaptureDevice.default(for: AVMediaType.video)
//        }
        
        let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: position)

        return device
    }
    
    deinit {
        self.stopCapture()
        self.videoOutput?.setSampleBufferDelegate(nil, queue: nil)
    }
    
    var allTargets = [OMImageConsumer]()
    
    func addTarget(target: OMImageConsumer) {
        allTargets.append(target)
    }
    
}

extension OMCamera {
    public func startCapture() {
        if !self.captureSession.isRunning {
            self.captureSession.startRunning()
        }
    }
    
    public func stopCapture() {
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
}

extension OMCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //处理摄像头采集的视频信息
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let width = CVPixelBufferGetWidth(cameraFrame)
        let height = CVPixelBufferGetHeight(cameraFrame)
        
        var outputTexture: OMTexture?
        
        if captureAsYUV {
            
        } else {
            var textureRef: CVMetalTexture? = nil
            let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, cameraFrame, nil, .bgra8Unorm, width, height, 0, &textureRef)
            
            if let ref = textureRef, let texture = CVMetalTextureGetTexture(ref) {
                outputTexture = OMTexture(texture: texture)
            }
        }
        
        if let t = outputTexture {
            self.updateAllTargets(texture: t)
        }
        
        if let delegate = self.delegate {
            delegate.cameraImageOutput(didOutput: sampleBuffer)
        }
    }
}

