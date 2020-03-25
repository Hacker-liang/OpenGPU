//
//  OGShaderLanguage.swift
//  MWVideoRecord
//
//  Created by langren on 2019/9/2.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation

let VertextShader =  """
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


public let ThreeInputVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;
attribute vec4 inputTextureCoordinate2;
attribute vec4 inputTextureCoordinate3;


varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;
varying vec2 textureCoordinate3;


void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
   
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
    
    
    func vertextShaderContent(textureCount: Int) -> String {
        return ThreeInputVertexShader
        
        if self == .framgment {
            fatalError("it's not suitable for fragment")
        }
        var shader = "attribute vec4 position;\n"
        for i in 0...textureCount {
            shader += "attribute vec4 inputTextureCoordinate".withNonZeroSuffix(i) + ";\n"
            shader += "varying highp vec2 textureCoordinate".withNonZeroSuffix(i) + ";\n"
        }
        shader +=
        """
        void main() {
            gl_Position = position;
        
        """
        
        for i in 0...textureCount {
            shader += "    textureCoordinate".withNonZeroSuffix(i) + " = inputTextureCoordinate".withNonZeroSuffix(i)+".xy;\n"
        }
        
        shader += "}"
        
        print(shader)
        return shader
    }
}

