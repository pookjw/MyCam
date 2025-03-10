//
//  CinematicObjectTracking.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/10/25.
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicObjectTracking : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;
@end

NS_ASSUME_NONNULL_END
