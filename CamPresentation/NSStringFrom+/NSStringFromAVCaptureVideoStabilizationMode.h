//
//  NSStringFromAVCaptureVideoStabilizationMode.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/9/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_VISION
CP_EXTERN NSString * NSStringFromAVCaptureVideoStabilizationMode(NSInteger videoStabilizationMode);
#else
CP_EXTERN NSString * NSStringFromAVCaptureVideoStabilizationMode(AVCaptureVideoStabilizationMode videoStabilizationMode);
#endif

NS_ASSUME_NONNULL_END
