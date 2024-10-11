//
//  PixelBufferLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/11/24.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelBufferLayer : CALayer
- (void)updateWithCIImage:(CIImage *)ciImage rotationAngle:(float)rotationAngle;
@end

NS_ASSUME_NONNULL_END
