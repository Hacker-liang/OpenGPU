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


fragment half4 faceBeautyFragmentShader(OneInputVertextOutput in [[stage_in]],
                                        texture2d<half> texture [[texture(0)]],
                                        const device float *faceEnable [[buffer(0)]],
                                        const device float2 *landmarks [[buffer(1)]]) {
    sampler tempSampler;

    bool isKeyPoint = false;
    for (int i=0; i<81; i++) {
        if(abs(landmarks[i].x/720 - in.textureCoordinate.x)<0.005 && abs(landmarks[i].y/1280 - in.textureCoordinate.y)<0.005) {
            isKeyPoint = true;
            break;
        }
    }
    
    
    if(isKeyPoint) {
        return half4(0.0,1.0,0.0,1.0);
    } else {
        return texture.sample(tempSampler, in.textureCoordinate);
    }
}

//
//fragment float4 faceBeautyFragment(OneInputVertextOutput in [[stage_in]], texture [[texture(0)]]) {
//
//}
