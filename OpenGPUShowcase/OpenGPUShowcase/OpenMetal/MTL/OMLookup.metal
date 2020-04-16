//
//  OMLookup.metal
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/8.
//  Copyright © 2020 langren. All rights reserved.
//

#include <metal_stdlib>
#include "MTLShaderTypes.h"

using namespace metal;

fragment half4 lookupFragmentFunc(TwoInputVertextOutput in [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  texture2d<half> inputTexture2 [[texture(1)]],
                                  device const float *intensity [[buffer(0)]]) {
    constexpr sampler qudaSampler;
    half4 base = inputTexture.sample(qudaSampler, in.textureCoordinate);

    //根据blue的颜色，找到色块的index
    half blueIndex = base.b * 63.0;

    half2 quad1;
    quad1.y = floor(floor(blueIndex)/8);
    quad1.x = floor((blueIndex-8*quad1.y)/8);

    half2 quad2;
    quad2.y = floor(ceil(blueIndex)/8);
    quad2.x = ceil((blueIndex-8*quad1.y)/8);

    half2 coordinate1;
    coordinate1.x = 0.125*quad1.x + 0.5/512 + (0.125 - 1.0/512)*base.r;
    coordinate1.y = 0.125*quad1.y + 0.5/512 + (0.125 - 1.0/512)*base.g;

    half2 coordinate2;
    coordinate2.x = 0.125*quad2.x + 0.5/512 + (0.125 - 1.0/512)*base.r;
    coordinate2.y = 0.125*quad2.y + 0.5/512 + (0.125 - 1.0/512)*base.g;

    constexpr sampler qudaSampler1;
    half4 lookupColor1 = inputTexture2.sample(qudaSampler1, float2(coordinate1));
    constexpr sampler qudaSampler2;
    half4 lookupColor2 = inputTexture2.sample(qudaSampler2, float2(coordinate2));

    half4 lookupMix = mix(lookupColor1, lookupColor2, fract(blueIndex));

    return half4(mix(base, half4(lookupMix.rgb, base.w), half(intensity[0])));
    
}
