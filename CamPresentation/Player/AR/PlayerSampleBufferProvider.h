//
//  PlayerSampleBufferProvider.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/15/24.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerSampleBufferProvider : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPlayer:(AVPlayer *)player handler:(void (^)(CMSampleBufferRef sampleBuffer))handler;
- (void)invalidate;
@end

NS_ASSUME_NONNULL_END
