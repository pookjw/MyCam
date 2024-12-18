//
//  ImageBufferLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/11/24.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
__attribute__((objc_direct_members))
@interface ImageBufferLayer : CALayer
- (void)updateWithCIImage:(CIImage * _Nullable)ciImage rotationAngle:(float)rotationAngle fill:(BOOL)fill;
- (void)updateWithCIImage:(CIImage * _Nullable)ciImage fill:(BOOL)fill;
- (void)updateWithCGImage:(CGImageRef _Nullable)cgImage fill:(BOOL)fill;
@end

NS_ASSUME_NONNULL_END
