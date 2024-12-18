//
//  ExposureRectLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/24/24.
//

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
__attribute__((objc_direct_members))
@interface ExposureRectLayer : CALayer
+ (instancetype)layer NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)captureDevice videoPreviewLayer:(AVCaptureVideoPreviewLayer *)videoPreviewLayer;
@end

NS_ASSUME_NONNULL_END
