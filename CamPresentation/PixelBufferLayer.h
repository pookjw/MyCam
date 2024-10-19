//
//  PixelBufferLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/11/24.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelBufferLayer : CALayer
- (void)updateWithCIImage:(CIImage * _Nullable)ciImage rotationAngle:(float)rotationAngle;
- (void)updateWithCGImage:(CGImageRef _Nullable)cgImage;
@end

NS_ASSUME_NONNULL_END
