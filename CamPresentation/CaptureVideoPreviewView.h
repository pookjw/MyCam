//
//  CaptureVideoPreviewView.h
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

@interface CaptureVideoPreviewView : UIView
#if TARGET_OS_VISION
@property (nonatomic, readonly) __kindof CALayer *captureVideoPreviewLayer;
#else
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
#endif
@end

NS_ASSUME_NONNULL_END
