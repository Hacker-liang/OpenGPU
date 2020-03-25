//
//  RGBFilter.swift
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/20.
//  Copyright © 2020 langren. All rights reserved.
//

import Foundation

fileprivate let FragmentShader = """
precision mediump float;
varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
void main()
{
    vec4 color = texture2D(inputImageTexture, textureCoordinate);
    gl_FragColor = vec4(color.r, color.b, color.g, 1);
}

"""

class RGBFilter: OGBaseFilter {
    override init(shader: OGShaderProgram, numberOfInputs: UInt = 1) {
        super.init(shader: shader, numberOfInputs: numberOfInputs)
    }
    
    convenience init() {
        let shader = OGEAGLContext.shared().programForVertext(OGShaderLanguage.vertex.shaderContent(), fragmentShader: FragmentShader)
        self.init(shader: shader, numberOfInputs: 1)
    }
}
