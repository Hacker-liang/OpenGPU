//
//  MTLShaderTypes.h
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/31.
//  Copyright © 2020 langren. All rights reserved.
//

#ifndef MTLShaderTypes_h
#define MTLShaderTypes_h

#include <metal_stdlib>
#include <simd/simd.h>

#define kOneInputVertexFunc ""

struct OneInputVertextOutput {
    
    float4 position [[position]];
    float2 textureCoordinate;
    
};

typedef struct OneInputVertextOutput OneInputVertextOutput;


typedef struct {
    
    float4 position [[position]];
    float2 textureCoordinate;
    float2 textureCoordinate2;
    
} TwoInputVertextOutput;




#endif /* MTLShaderTypes_h */
