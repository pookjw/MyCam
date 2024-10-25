//
//  ExposureRectLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/24/24.
//

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExposureRectLayer : CALayer
+ (instancetype)layer NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
#if TARGET_OS_VISION
- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)captureDevice videoPreviewLayer:(__kindof CALayer *)videoPreviewLayer;
#else
- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)captureDevice videoPreviewLayer:(AVCaptureVideoPreviewLayer *)videoPreviewLayer;
#endif
@end

NS_ASSUME_NONNULL_END
