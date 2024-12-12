//
//  ARPlayerRenderType.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/12/24.
//

#import <CamPresentation/ARPlayerRenderType.h>

ARPlayerRenderType * allARPlayerRenderTypes(NSUInteger * _Nullable count) {
    static ARPlayerRenderType types[] {
        ARPlayerRenderTypeAVPlayer,
        ARPlayerRenderTypeVideoRenderer
    };
    
    if (count) *count = 2;
    
    return types;
}

NSString * NSStringFromARPlayerRenderType(ARPlayerRenderType renderType) {
    switch (renderType) {
        case ARPlayerRenderTypeAVPlayer:
            return @"AVPlayer";
        case ARPlayerRenderTypeVideoRenderer:
            return @"AVSampleBufferVideoRenderer";
        default:
            abort();
    }
}
