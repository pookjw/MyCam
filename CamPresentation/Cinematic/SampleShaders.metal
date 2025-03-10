//
//  SampleShaders.metal
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#include <metal_stdlib>
using namespace metal;

struct RasterizerData {
    float4 position [[position]];
    float4 color;
};

vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                                                   constant float2 *vertices [[buffer(0)]],
                                                   constant float4& color [[buffer(1)]])
{
    RasterizerData out;
    out.position = vector_float4(0.f, 0.f, 0.f, 1.f);
    out.position.xy = (vertices[vertexID] * 2.f) - 1.f;
    out.color = color;
    return out;
}

fragment float4 fragmentShader_YFormat(RasterizerData in [[stage_in]]) {
    return in.color;
}

fragment float4 fragmentShader_CbCrFormat(RasterizerData in [[stage_in]]) {
    return in.color;
}
