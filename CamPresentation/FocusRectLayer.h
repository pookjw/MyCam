//
//  FocusRectLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FocusRectLayer : CALayer
+ (instancetype)layer NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)captureDevice;
@end

NS_ASSUME_NONNULL_END
