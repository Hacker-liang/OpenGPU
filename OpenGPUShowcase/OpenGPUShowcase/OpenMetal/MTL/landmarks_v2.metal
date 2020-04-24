//
//  OMFaceBeautyMTL.metal
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/16.
//  Copyright © 2020 langren. All rights reserved.
//

#include <metal_stdlib>
#include "MTLShaderTypes.h"
#include <simd/simd.h>

//fragment half4 commonFragmentShader(OneInputVertextOutput in [[stage_in]],
//                                     texture2d<half> texture [[texture(0)]]) {
//    constexpr sampler qudaSampler;
//    half4 color = texture.sample(qudaSampler, in.textureCoordinate);
//    return color;
//}

using namespace metal;

typedef struct
{
    float4 faceThinPoint[9];  //瘦脸关键点坐标 (x,y)是原始点坐标  (z,w)是目标点坐标 （像素坐标）

    float4 eyeBigPoints[2];   //大眼关键点坐标 (x,y)圆中心坐标  (z,w)是目标点坐标 （像素坐标）

    float4 noseThinPoints[4];  //瘦鼻子关键点坐标(x,y)是原始点坐标  (z,w)是目标点坐标 (像素坐标)

} FaceLandmarks;

typedef struct
{
    float faceThinIntensity;
    float eyeBigIntensity;
    float noseThinIntensity;
    
} FaceIntensity;

typedef struct
{
    float textureWidth;
    float textureHeight;
} TextureResolution;

fragment half4 faceBeautyFragmentShader_v2(OneInputVertextOutput in [[stage_in]],
                                        texture2d<half> texture [[texture(0)]],
                                        const device FaceLandmarks *landmarks [[buffer(1)]],
                                        const device FaceIntensity *faceIntensity [[buffer(2)]],
                                        const device TextureResolution *resolution [[buffer(3)]],
                                        const device bool *faceEnable [[buffer(4)]],
                                        const device float2 *offsetValues [[buffer(5)]]
) {
    sampler tempSampler;
    
    float2 coordinate = in.textureCoordinate;
    if (faceEnable[0] == true) {
        
        float resolutionW = resolution->textureWidth;
        float resolutionH = resolution->textureHeight;
        coordinate = coordinate*float2(resolutionW, resolutionH);

//        float *v = [211,   186,  228,  203,  231,  210,  205, 199,  204];
        if (faceIntensity->faceThinIntensity > 0.0) {

            for (int i = 0; i<9; i++) {
                float2 originPoint = float2(landmarks->faceThinPoint[i].x, landmarks->faceThinPoint[i].y);
                float2 targetPoint = float2(landmarks->faceThinPoint[i].z, landmarks->faceThinPoint[i].w);

                float radius = distance(targetPoint, originPoint);
                
                float radius1 = distance(coordinate, originPoint);
                
                if (radius1<radius) {
                    int index = clamp(int(radius1/radius*100), 0, 99);
                    
                    float2 off = offsetValues[i*100+index];
                    
                    coordinate = coordinate - off;
                    
    
                }
                
                if(abs(landmarks->faceThinPoint[i].x/720 - in.textureCoordinate.x)<0.003 && abs(landmarks->faceThinPoint[i].y/1280 - in.textureCoordinate.y)<0.003) {
                    return half4(1.0,0.0,0.0,1.0);
                }
            }
            
        }
        
        if (faceIntensity->eyeBigIntensity>0.0) {
            for (int i = 0; i<2; i++) {
                float2 originPoint = float2(landmarks->eyeBigPoints[i].x, landmarks->eyeBigPoints[i].y);
                float2 targetPoint = float2(landmarks->eyeBigPoints[i].z, landmarks->eyeBigPoints[i].w);
                float radius = distance(targetPoint, originPoint)*3.0;
                
                float weight = distance(coordinate, originPoint)/radius;
                weight = 1.0 - (1.0-pow(weight,2.0))*faceIntensity->eyeBigIntensity;
                weight = clamp(weight, 0.0, 1.0);
                coordinate = originPoint + (coordinate-originPoint)*weight;
                if(abs(landmarks->eyeBigPoints[i].x/720 - in.textureCoordinate.x)<0.003 && abs(landmarks->eyeBigPoints[i].y/1280 - in.textureCoordinate.y)<0.003) {
                    return half4(1.0,0.0,0.0,1.0);
                }
            }
        }
        
        if (faceIntensity->noseThinIntensity>0.0) {
            for (int i = 0; i<4; i++) {
                if(abs(landmarks->noseThinPoints[i].x/720 - in.textureCoordinate.x)<0.003 && abs(landmarks->noseThinPoints[i].y/1280 - in.textureCoordinate.y)<0.003) {
                    return half4(1.0,0.0,0.0,1.0);
                }
                
                float2 originPoint = float2(landmarks->noseThinPoints[i].x, landmarks->noseThinPoints[i].y);
                float2 targetPoint = float2(landmarks->noseThinPoints[i].z, landmarks->noseThinPoints[i].w);
                
                float2 offset = float2(0.0);
                float2 direction = (targetPoint - originPoint)*faceIntensity->noseThinIntensity;
                float radius = distance(targetPoint, originPoint);
                float infect = 1.0-distance(coordinate, originPoint)/radius;  //距离形变起始点越近形变越大
                
                infect = clamp(infect, 0.0, 1.0);
                offset = direction * infect;
                coordinate = coordinate - offset;
                
                
            }
        }
        
        coordinate = coordinate/float2(resolutionW, resolutionH);

    }
    

    
    return texture.sample(tempSampler, coordinate);
}



//
//fragment float4 faceBeautyFragment(OneInputVertextOutput in [[stage_in]], texture [[texture(0)]]) {
//
//}
