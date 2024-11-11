//
//  pixel_buffer_shader.metal
//  Booth
//
//  Created by Jinwoo Kim on 9/24/23.
//

#include <metal_stdlib>
using namespace metal;

namespace pixel_buffer_shader {
    typedef struct {
        float2 position [[attribute(0)]];
        float2 texCoord [[attribute(1)]];
    } ImageVertex;
    
    struct VertexIO {
        float4 position [[position]];
        float2 textureCoord [[user(texturecoord)]];
    };
    
    vertex VertexIO vertexFunction(ImageVertex in [[stage_in]])
    {
        return {
            .position = float4(in.position, 0.0, 1.0),
            .textureCoord = in.texCoord
        };
    }
    
    fragment float4 fragmentFunction(VertexIO inoutFragment [[stage_in]],
                                    texture2d<float, access::sample> capturedImageTextureY [[ texture(0) ]],
                                    texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(1) ]])
    {
        constexpr sampler colorSampler(mip_filter::linear,
                                           mag_filter::linear,
                                           min_filter::linear);
        
        const float4x4 ycbcrToRGBTransform = float4x4(
            float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
            float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
            float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
            float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
        );
        
        float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, inoutFragment.textureCoord).r,
                              capturedImageTextureCbCr.sample(colorSampler, inoutFragment.textureCoord).rg, 1.0);
        
        return ycbcrToRGBTransform * ycbcr;
    }
}
