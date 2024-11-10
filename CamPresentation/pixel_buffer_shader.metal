//
//  pixel_buffer_shader.metal
//  Booth
//
//  Created by Jinwoo Kim on 9/24/23.
//

#include <metal_stdlib>
using namespace metal;

namespace pixel_buffer_shader {
    struct VertexIO {
        float4 position [[position]];
        float2 textureCoord [[user(texturecoord)]];
    };
    
    vertex VertexIO vertexFunction(const device packed_float4 *positions [[buffer(0)]],
                                   const device packed_float2 *textrueCoords [[buffer(1)]],
                                   uint vertexID [[vertex_id]])
    {
        return {
            .position = positions[vertexID],
            .textureCoord = textrueCoords[vertexID]
        };
    }
    
    fragment float4 fragmentFunction(VertexIO inoutFragment [[stage_in]],
                                    texture2d<float, access::sample> capturedImageTextureY [[ texture(0) ]],
                                    texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(1) ]],
                                    sampler samplr [[sampler(0)]])
    {
//        return inputTexture.sample(samplr, inoutFragment.textureCoord);
        const float4x4 ycbcrToRGBTransform = float4x4(
            float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
            float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
            float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
            float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
        );
        
        // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
        float4 ycbcr = float4(capturedImageTextureY.sample(samplr, inoutFragment.position.xy).r,
                              capturedImageTextureCbCr.sample(samplr, inoutFragment.position.xy).rg, 1.0);
        
        // Return converted RGB color
        return ycbcrToRGBTransform * ycbcr;
    }
}
