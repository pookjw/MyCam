//
//  AudioWaveLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface AudioWaveLayer : CALayer
@property (assign, nonatomic, null_resettable) CGColorRef waveColor;
- (void)nonisolated_processSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
