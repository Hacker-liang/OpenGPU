//
//  RenderPass.metal
//  OpenGPUShowcase
//
//  Created by langren on 2020/3/31.
//  Copyright © 2020 langren. All rights reserved.
//

#include <metal_stdlib>
#include "MTLShaderTypes.h"
#include <simd/simd.h>

using namespace metal;

typedef struct {
    
    float4 position [[position]];
    float2 textureCoordinate;
    
} OneInputVertextOutput;

typedef struct {
    
    float4 position [[position]];
    float2 textureCoordinate;
    float2 textureCoordinate2;
    
} TwoInputVertextOutput;


vertex OneInputVertextOutput oneInputVertexShader(const device packed_float2 *position [[buffer(0)]],
                                         const device packed_float2 *coordinate [[buffer(1)]],
                                         uint vid [[vertex_id]]) {
    OneInputVertextOutput output;
    output.position = vector_float4(position[vid], 0.0, 1.0);
    output.textureCoordinate = coordinate[vid];
    return output;
}


vertex TwoInputVertextOutput twoInputVetexShader(const device packed_float2 *position [[buffer(0)]],
                                                 const device packed_float2 *coordinate [[buffer(1)]],
                                                 const device packed_float2 *coordinate2 [[buffer(2)]],
                                                 uint vid [[vertex_id]]) {
    TwoInputVertextOutput output;
    output.position = vector_float4(position[vid], 0.0, 1.0);
    output.textureCoordinate = coordinate[vid];
    output.textureCoordinate2 = coordinate2[vid];
    
    return output;
}

fragment half4 commonFragmentShader(OneInputVertextOutput in [[stage_in]],
                                     texture2d<half> texture [[texture(0)]]) {
    constexpr sampler qudaSampler;
    half4 color = texture.sample(qudaSampler, in.textureCoordinate);
    return color;
}


