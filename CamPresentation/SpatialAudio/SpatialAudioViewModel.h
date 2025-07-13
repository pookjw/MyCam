//
//  SpatialAudioViewModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/13/25.
//

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION && !TARGET_OS_SIMULATOR
#import <Cinematic/Cinematic.h>
#endif

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0), visionos(26.0))
@interface SpatialAudioViewModel : NSObject
@property (retain, nonatomic, readonly) AVPlayer *player;
#if !TARGET_OS_VISION && !TARGET_OS_SIMULATOR
@property (assign, nonatomic) CNSpatialAudioRenderingStyle renderingStyle;
#else
@property (assign, nonatomic) NSInteger renderingStyle;
#endif
@property (assign, nonatomic) Float32 effectIntensity;
- (void)updateWithPHAsset:(PHAsset *)phAsset completionHandler:(void (^)(NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
