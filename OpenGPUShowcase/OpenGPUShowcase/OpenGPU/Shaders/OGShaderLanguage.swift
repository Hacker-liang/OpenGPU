//
//  OGShaderLanguage.swift
//  MWVideoRecord
//
//  Created by langren on 2019/9/2.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation

fileprivate let VertextShader =  """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;
varying highp vec2 textureCoordinate;
void main() {
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
}
"""

fileprivate let FragmentShader = """
varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
void main() {
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
}
"""



enum OGShaderLanguage {
    case vertex
    case framgment
    
    func shaderContent() -> String {
        switch self {
        case .vertex:
            return VertextShader
        case .framgment:
            return FragmentShader
        }
    }
}

