//
//  CinematicObjectTracking.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/10/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <Metal/Metal.h>
#import <CamPresentation/CinematicAssetData.h>

NS_ASSUME_NONNULL_BEGIN

// Thread-safe하지 않음
@interface CinematicObjectTracking : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;
- (void)handleObjectTrackingWithAssetData:(CinematicAssetData *)cinematicAssetData pointOfInterest:(CGPoint)pointOfInterest timeRange:(CMTimeRange)timeRange strongDecision:(BOOL)strongDecision;
@end

NS_ASSUME_NONNULL_END

#endif
