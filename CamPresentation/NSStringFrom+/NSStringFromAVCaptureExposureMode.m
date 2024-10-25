//
//  NSStringFromAVCaptureExposureMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <CamPresentation/NSStringFromAVCaptureExposureMode.h>

#if TARGET_OS_VISION
NSString * NSStringFromAVCaptureExposureMode(NSInteger exposureMode)
#else
NSString * NSStringFromAVCaptureExposureMode(AVCaptureExposureMode exposureMode)
#endif
{
    switch (exposureMode) {
#if TARGET_OS_VISION
        case 0:
#else
        case AVCaptureExposureModeLocked:
#endif
            return @"Locked";
#if TARGET_OS_VISION
        case 1:
#else
        case AVCaptureExposureModeAutoExpose:
#endif
            return @"Auto Expose";
#if TARGET_OS_VISION
        case 2:
#else
        case AVCaptureExposureModeContinuousAutoExposure:
#endif
            return @"Continuous Auto Exposure";
#if TARGET_OS_VISION
        case 3:
#else
        case AVCaptureExposureModeCustom:
#endif
            return @"Custom";
        default:
            abort();
    }
}
