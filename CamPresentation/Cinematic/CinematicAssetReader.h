//
//  CinematicAssetReader.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <CamPresentation/CinematicAssetData.h>
#import <CamPresentation/CinematicSampleBuffer.h>

NS_ASSUME_NONNULL_BEGIN

// Thread-safe하지 않음
@interface CinematicAssetReader : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAssetData:(CinematicAssetData *)assetData;
- (void)setupReadingWithTimeRange:(CMTimeRange)timeRange;
- (void)cancelReading;
- (CinematicSampleBuffer * _Nullable)nextSampleBuffer NS_RETURNS_RETAINED;
@end

NS_ASSUME_NONNULL_END

#endif
