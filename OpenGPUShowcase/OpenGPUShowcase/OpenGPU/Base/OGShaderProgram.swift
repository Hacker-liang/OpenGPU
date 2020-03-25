//
//  OGShaderProgram.swift
//  MWVideoRecord
//
//  Created by langren on 2019/8/29.
//  Copyright © 2019 langren. All rights reserved.
//

import Foundation
import OpenGLES

enum OGShaderType {
    case vertex //顶点
//    case geometry //几何   OpenglES 3.0暂时不支持几何着色器
    case fragment //片段
}

public class OGShaderProgram {
    
    let program: GLuint
    private var vertexShader: GLuint?
    private var fragmentShader: GLuint?
    
    //保存attribute在GPU的index，用来在cpu(顶点着色器)和gpu中进行数据传递
    private var attributeLocationInGPU = [String: GLuint]()
    
    //保存uniform在GPU的index，用来在cpu和gpu中进行数据传递
    private var uniformLocationInGPU = [String: GLint]()
    
    //保存当前已设置的uniform格式的值
    private var currentSettedUniformValues = [String: Any]()
    
    init(vertexShaderString: String, fragmentShaderString: String) {
        program = glCreateProgram()
        
        self.vertexShader = compileShader(shaderString: vertexShaderString, type: .vertex)
        self.fragmentShader = compileShader(shaderString: fragmentShaderString, type: .fragment)
        
        if let vertex_s = vertexShader {
            glAttachShader(program, vertex_s)
        }
        if let fragment_s = fragmentShader {
            glAttachShader(program, fragment_s)
        }
        self.link()
    }
    
    convenience init?(vertexShader vertexFile: URL, frgamentFile: URL) {
        guard let vertexStr = OGShaderProgram.shaderFromFile(file: vertexFile), let fragmentStr = OGShaderProgram.shaderFromFile(file: frgamentFile) else {
            return nil
        }
        self.init(vertexShaderString: vertexStr, fragmentShaderString: fragmentStr)
    }
    
    deinit {
        if vertexShader != nil {
            glDeleteShader(vertexShader!)
        }
        if fragmentShader != nil {
            glDeleteShader(fragmentShader!)
        }
    }
    
    private func compileShader(shaderString: String, type: OGShaderType) -> GLuint {
        let shader: GLuint
        switch type {
        case .vertex:
            shader = glCreateShader(GLenum(GL_VERTEX_SHADER))
        case .fragment:
            shader = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
        }
        
        if let valued = shaderString.cString(using:String.Encoding.utf8) {
            let d = UnsafePointer<GLchar>(valued)
            
            var tempString: UnsafePointer<GLchar>? = d
            //加载shader
            glShaderSource(shader, 1, &tempString, nil)
            //编译shader
            glCompileShader(shader)
            
        } else {
            fatalError("error glsl")
        }
        
//        var tempString:UnsafePointer<GLchar>? = shaderString.GLchar_Pointer()
//
//        //加载shader
//        glShaderSource(shader, 1, &tempString, nil)
//        //编译shader
//        glCompileShader(shader)
        
//        if let value = shaderString.cString(using:String.Encoding.utf8) {
//            var tempString:UnsafePointer<GLchar>? = UnsafePointer<GLchar>(value)
//            glShaderSource(shader, 1, &tempString, nil)
//            glCompileShader(shader)
//        } else {
//            fatalError("Could not convert this string to UTF8: \(self)")
//        }
        
//        shaderString.withGLChar{ glString in
//            var tempString:UnsafePointer<GLchar>? = glString
//            glShaderSource(shader, 1, &tempString, nil)
//            glCompileShader(shader)
//        }
        
        
        
        //检查编译结果
        var compileStatus: GLint = 1
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compileStatus)
        if compileStatus != 1 {
            var logLength: GLint = 0
            
            glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            var compileLog = [CChar](repeating:0, count:Int(logLength))
            
            glGetShaderInfoLog(shader, logLength, &logLength, &compileLog)
            print("Compile log: \(String(cString:compileLog))")
            switch type {
                case .vertex: fatalError("Vertex shader compile error:")
                case .fragment: fatalError("Fragment shader compile error:")
            }
        }
        return shader
    }
    
    //链接着色器
    private func link() {
        glLinkProgram(program)
        var linkStatus: GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == 0 {  //如果链接失败
            print("link program error")
            var logLength:GLint = 0
            glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if (logLength > 0) {
                var compileLog = [CChar](repeating:0, count:Int(logLength))
                glGetProgramInfoLog(program, logLength, &logLength, &compileLog)
                print("Link log: \(String(cString:compileLog))")
            }
        }
    }
    
    private func setUniformValue<T: Equatable>(value: T, forUniform uniform: String) {
        guard let location = self.uniformLocation(uniform: uniform) else {
            print("当前着色器里并没有设置：\(uniform)")
            return
        }
        //与已设置的值进行对比，只有不相同的情况才向GPU传值，主要是为了节省性能
        if let oldValue = currentSettedUniformValues[uniform] as? T, oldValue == value {
        } else {
            self.glUniformX(value: value, forUniformLocation: location)
            currentSettedUniformValues[uniform] = value
        }
    }
    
    private func glUniformX(value: Any, forUniformLocation location: GLint) {
        if value is GLint {
            glUniform1i(location, value as! GLint)
            
        } else if value is GLfloat {
            glUniform1f(location, value as! GLfloat)
            
        } else if value is [GLfloat] {
            let arrayValue: [GLfloat] = value as! [GLfloat]
            
            if arrayValue.count > 1 && arrayValue.count <= 4 { //传递向量
                if (arrayValue.count == 2) {
                    glUniform2fv(location, 1, arrayValue)
                } else if (arrayValue.count == 3) {
                    glUniform3fv(location, 1, arrayValue)
                } else if (arrayValue.count == 4) {
                    glUniform4fv(location, 1, arrayValue)
                }
                
            } else if arrayValue.count == 9 || arrayValue.count == 16 { //传递矩阵
                if (arrayValue.count == 9) {
                    glUniformMatrix3fv(location, 1, GLboolean(GL_FALSE), arrayValue)
                } else if (arrayValue.count == 16) {
                    glUniformMatrix4fv(location, 1, GLboolean(GL_FALSE), arrayValue)
                }
            }
        }
    }
}

extension OGShaderProgram {
    //使用当前着色器
    public func use() {
        glUseProgram(program)
    }
    
    //获得attribute在GPU的索引位置
    public func attributeLocation(attribute: String) -> GLuint? {
        if let l = attributeLocationInGPU[attribute] {
            return l
        }
        var location: GLint = -1
        
        attribute.withGLChar { (glString) in
            location = glGetAttribLocation(self.program, glString)
        }
        if location < 0 {
            return nil
        } else {
            //从gpu获取到当前属性的位置之后，先激活
            glEnableVertexAttribArray(GLuint(location))
            attributeLocationInGPU[attribute] = GLuint(location)
            return GLuint(location)
        }
    }
    
    //获得uniform在GPU的索引位置
    public func uniformLocation(uniform: String) -> GLint? {
        if let location = uniformLocationInGPU[uniform] {
            return location
            
        } else {
            var location: GLint = -1
            uniform.withGLChar { (glString) in
                location = glGetUniformLocation(self.program, glString)
            }
            if location >= 0 {
                uniformLocationInGPU[uniform] = location
                return location
            }
        }
        return nil
    }
    
    public func setValue(value: GLfloat, forUniform uniform: String) {
        self.setUniformValue(value: value, forUniform: uniform)
    }
    
    public func setValue(value: GLint, forUniform uniform: String) {
        self.setUniformValue(value: value, forUniform: uniform)
    }
    
    public func setValue(value: [GLfloat], forUniform uniform: String) {
        self.setUniformValue(value: value, forUniform: uniform)
    }
}

extension OGShaderProgram {
    fileprivate class func shaderFromFile(file: URL) -> String? {
        guard FileManager.default.fileExists(atPath: file.path) else {
            return nil
        }
        do {
            let shaderString = try NSString(contentsOfFile: file.path, encoding: String.Encoding.ascii.rawValue)
            return shaderString as String
            
        } catch {
            return nil
        }
    }
}

extension String {
    
    func withGLChar(_ operation:(UnsafePointer<GLchar>) -> ()) {
           if let value = self.cString(using:String.Encoding.utf8) {
               operation(UnsafePointer<GLchar>(value))
           } else {
               fatalError("Could not convert this string to UTF8: \(self)")
           }
       }
}
