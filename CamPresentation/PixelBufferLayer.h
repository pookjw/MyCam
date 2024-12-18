//
//  PixelBufferLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/10/24.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface PixelBufferLayer : CALayer
- (void)updateWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

NS_ASSUME_NONNULL_END
