//
//  CinematicSnapshot.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/CinematicAssetData.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface CinematicSnapshot : NSObject
@property (copy, nonatomic, readonly) AVComposition *composition;
@property (copy, nonatomic, readonly) AVVideoComposition *videoComposition;
@property (retain, nonatomic, readonly) CNCompositionInfo *compositionInfo;
@property (retain, nonatomic, readonly) CNRenderingSession *renderingSession;
@property (retain, nonatomic, readonly) CinematicAssetData *assetData;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition compositionInfo:(CNCompositionInfo *)compositionInfo renderingSession:(CNRenderingSession *)renderingSession assetData:(CinematicAssetData *)assetData;
@end

NS_ASSUME_NONNULL_END
