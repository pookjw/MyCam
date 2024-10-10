//
//  PixelBufferLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/11/24.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelBufferLayer : CALayer
@property (assign, nonatomic) CVPixelBufferRef pixelBuffer;
@end

NS_ASSUME_NONNULL_END
