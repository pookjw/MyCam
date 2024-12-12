//
//  ARPlayerRenderType.h
//  MyCam
//
//  Created by Jinwoo Kim on 12/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ARPlayerRenderType) {
    ARPlayerRenderTypeAVPlayer,
    ARPlayerRenderTypeVideoRenderer
};

// don't call free()
ARPlayerRenderType * allARPlayerRenderTypes(NSUInteger * _Nullable count);

NSString * NSStringFromARPlayerRenderType(ARPlayerRenderType renderType);

NS_ASSUME_NONNULL_END
