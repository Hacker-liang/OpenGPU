//
//  coordinateOffsetCalculator.metal
//  OpenGPUShowcase
//
//  Created by langren on 2020/4/21.
//  Copyright © 2020 langren. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;


kernel void coordinateOffsetComputeFunc(device const float4* keyPoints,
                            device const float2* viewportSize,
                            device const float* intensity,
                            device float2* offsetResult,
                                        uint index [[thread_position_in_grid]]) {
    
    for(int index=0; index<9; index++) {
        
        float2 fromPoint = float2(keyPoints[index].x, keyPoints[index].y);
        float2 toPoint = float2(keyPoints[index].z, keyPoints[index].w);

        float radius = distance(fromPoint, toPoint);

        float tev = radius*0.01;
        
        for(int x=0; x<100; x++) {
            
            
//           
//            float2 offset = float2(0.0);
//            
//            float2 direction = (targetPoint - originPoint)*faceIntensity->faceThinIntensity;
//            float radius = distance(targetPoint, originPoint);
//            float infect = 1.0-distance(coordinate, originPoint)/radius;  //距离形变起始点越近形变越大
//                           
//            infect = clamp(infect, 0.0, 1.0);
//            offset = direction * infect;
            
            
            
            float2 offset = float2(0.0, 0.0);
            float2 direction = (toPoint - fromPoint)*intensity[0];
            float infect = 1.0 - tev*x/radius;  //距离形变起始点越近形变越大
            
            infect = clamp(infect, 0.0, 1.0);
            offset = direction * infect;
            
//            float infect = 1.0-distance(coordinate, originPoint)/radius;  //距离形变起始点越近形变越大
//            
//            infect = clamp(infect, 0.0, 1.0);
//            offset = direction * infect;
            
            
            offsetResult[index*100+x] = offset;
        }
    }
}
