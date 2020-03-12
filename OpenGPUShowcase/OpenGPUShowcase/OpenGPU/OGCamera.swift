//
//  OGCamera.swift
//  MWVideoRecord
//
//  Created by langren on 2019/8/27.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation
import AVFoundation

class OGCamera: NSObject, OGImageProvider {
    var targetContainer: OGTargetContainer
    
    let captureAsYUV: Bool  //是否以YUV的格式进行视频捕获
    
    private var captureSession: AVCaptureSession!
    private var captureDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var cameraPosition: AVCaptureDevice.Position!
    private var capturePreset: AVCaptureSession.Preset!
    
    private var cameraProcessQueue: DispatchQueue?  //视频处理队列
    
    init(capturePreset: AVCaptureSession.Preset, cameraPosition :AVCaptureDevice.Position = .back, captureAsYUV: Bool = true) {
        self.capturePreset = capturePreset
        self.captureAsYUV = captureAsYUV
        self.cameraPosition = cameraPosition
        
        self.targetContainer = OGTargetContainer()
        super.init()
        self.configCamera()
    }
    
    deinit {
        self.stopCapture()
        self.videoOutput?.setSampleBufferDelegate(nil, queue: nil)
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
        let devices = AVCaptureDevice.devices(for:AVMediaType.video)
        for case let device in devices {
            if (device.position == position) {
                return device
            }
        }
        
        return AVCaptureDevice.default(for: AVMediaType.video)
    }
}

extension OGCamera {
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

extension OGCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //处理摄像头采集的视频信息
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        OGEAGLContext.shared().runOperationAsynchronously {
            var cameraFramebuffer: OGFramebuffer
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            let startTime = CFAbsoluteTimeGetCurrent()
            let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
            let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)
            let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
            
            if self.captureAsYUV {
                cameraFramebuffer = OGEAGLContext.shared().framebufferCache.requestFrameBuffer(orentation: .portrait, size: CGSize(width: bufferWidth, height: bufferHeight), textureOnly: true)
                
                cameraFramebuffer.tag = "Use In Camera Capture"
                
            } else { //如果不是以yuv格式进行采集的，则不需要渲染，直接将数据上传到纹理上即可
                
                var textureRef: CVOpenGLESTexture? = nil
                
                let _ = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, OGEAGLContext.shared().coreVideoTextureCache, pixelBuffer, nil, GLenum(GL_TEXTURE_2D), GL_RGBA, GLsizei(bufferWidth), GLsizei(bufferHeight), GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), 0, &textureRef)
                
                let texture = CVOpenGLESTextureGetName(textureRef!)

                glActiveTexture(GLenum(GL_TEXTURE5))
                glBindTexture(GLenum(GL_TEXTURE_2D), texture)
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
                
                glBindTexture(GLenum(GL_TEXTURE_2D), 0)
                
                cameraFramebuffer = OGEAGLContext.shared().framebufferCache.requestFrameBuffer(orentation: .portrait, size: CGSize(width: bufferWidth, height: bufferHeight), textureOnly: true, overridetexture: texture)
                
//                cameraFramebuffer.tag = "Use In Camera Capture"
//
//                glBindTexture(GLenum(GL_TEXTURE_2D), cameraFramebuffer.texture!)
//                glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(bufferWidth), GLsizei(bufferHeight), 0, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddress(pixelBuffer))
//                glBindBuffer(GLenum(GL_TEXTURE_2D), 0)
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
            
            self.updateTargets(withFramebuffer: cameraFramebuffer)
        }
        
    }
}


