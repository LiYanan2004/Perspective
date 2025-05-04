//
//  WarpPerspective.metal
//  Perspective
//
//  Created by Yanan Li on 2025/5/4.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]]
float2 warpPerspective(float2 position, float3 c0, float3 c1, float3 c2, float2 viewSize) {
    float3x3 H = float3x3(c0, c1, c2);
    float3 posH = float3(position, 1.0);
    float3 transformed = H * posH;
    float2 correctedPos = transformed.xy / transformed.z;
    return correctedPos;
}
