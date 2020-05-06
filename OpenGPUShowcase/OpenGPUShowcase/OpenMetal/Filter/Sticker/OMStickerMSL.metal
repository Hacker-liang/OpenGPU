//
//  OMStickerMSL.metal
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/24.
//  Copyright © 2020 langren. All rights reserved.
//

#include <metal_stdlib>
#include "OMStickerHeaders.h"

using namespace metal;

vertex StickerVertextOutput stickerVertexShader(const device packed_float2 *position [[buffer(0)]],
                                                       const device packed_float2 *coordinate [[buffer(1)]],
                                                      const device int *textureCount,
                                                       uint vid [[vertex_id]]) {
    StickerVertextOutput output;
    
    output.position = vector_float4(position[vid], 0.0, 1.0);
    
//    output.textureCoordinate = coordinate[vid];

    
    int index = vid/4;

    if (index == 0) {
        output.textureCoordinate = coordinate[vid-index*4];

    } else if (index == 1) {
        output.textureCoordinate2 = coordinate[vid-index*4];

    } else if (index == 2) {
        output.textureCoordinate3 = coordinate[vid-index*4];

    } else if (index == 3) {
        output.textureCoordinate4 = coordinate[vid-index*4];

    } else if (index == 4) {
        output.textureCoordinate5 = coordinate[vid-index*4];
    }
////
    return output;
}


fragment half4 stickerFragmentShader(StickerVertextOutput in [[stage_in]],
                                      array<texture2d<half>, 5> textures) {
    
    constexpr sampler qudaSample;
    half4 color;
    
    color = textures[0].sample(qudaSample, in.textureCoordinate);
    
    for(uint index=0; index<textures.size(); index++) {
        if (index == 0 && !(in.textureCoordinate.x < 0.0 || in.textureCoordinate.x > 1.0 || in.textureCoordinate.y < 0.0 || in.textureCoordinate.y > 1.0)) {
            color = textures[0].sample(qudaSample, in.textureCoordinate);

        } else if (index == 1 && !(in.textureCoordinate2.x < 0.0 || in.textureCoordinate2.x > 1.0 || in.textureCoordinate2.y < 0.0 || in.textureCoordinate2.y > 1.0)) {
            color = textures[1].sample(qudaSample, in.textureCoordinate2);

        } else if (index == 2 && !(in.textureCoordinate3.x < 0.0 || in.textureCoordinate3.x > 1.0 || in.textureCoordinate3.y < 0.0 || in.textureCoordinate3.y > 1.0)) {
            color = textures[2].sample(qudaSample, in.textureCoordinate3);

        } else if (index == 3 && !(in.textureCoordinate4.x < 0.0 || in.textureCoordinate4.x > 1.0 || in.textureCoordinate4.y < 0.0 || in.textureCoordinate4.y > 1.0)) {
            color = textures[3].sample(qudaSample, in.textureCoordinate4);

        } else if (index == 4 && !(in.textureCoordinate5.x < 0.0 || in.textureCoordinate5.x > 1.0 || in.textureCoordinate5.y < 0.0 || in.textureCoordinate5.y > 1.0)) {
            color = textures[4].sample(qudaSample, in.textureCoordinate5);
        }
    }
    return color;
}


