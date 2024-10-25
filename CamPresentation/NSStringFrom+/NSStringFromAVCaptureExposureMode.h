//
//  NSStringFromAVCaptureExposureMode.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_VISION
CP_EXTERN NSString * NSStringFromAVCaptureExposureMode(NSInteger exposureMode);
#else
CP_EXTERN NSString * NSStringFromAVCaptureExposureMode(AVCaptureExposureMode exposureMode);
#endif

NS_ASSUME_NONNULL_END
