//
//  CinematicCompositions.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface CinematicCompositions : NSObject
@property (copy, nonatomic, readonly) AVComposition *composition;
@property (copy, nonatomic, readonly) AVVideoComposition *videoComposition;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition;
@end

NS_ASSUME_NONNULL_END
