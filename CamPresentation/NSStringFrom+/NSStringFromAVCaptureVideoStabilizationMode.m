//
//  NSStringFromAVCaptureVideoStabilizationMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/9/24.
//

#import <CamPresentation/NSStringFromAVCaptureVideoStabilizationMode.h>

#if TARGET_OS_VISION
NSString * NSStringFromAVCaptureVideoStabilizationMode(NSInteger videoStabilizationMode)
#else
NSString * NSStringFromAVCaptureVideoStabilizationMode(AVCaptureVideoStabilizationMode videoStabilizationMode)
#endif
{
    switch (videoStabilizationMode) {
#if TARGET_OS_VISION
        case 0:
#else
        case AVCaptureVideoStabilizationModeOff:
#endif
            return @"Off";
#if TARGET_OS_VISION
        case 1:
#else
        case AVCaptureVideoStabilizationModeStandard:
#endif
            return @"Standard";
#if TARGET_OS_VISION
        case 2:
#else
        case AVCaptureVideoStabilizationModeCinematic:
#endif
            return @"Cinematic";
#if TARGET_OS_VISION
        case 3:
#else
        case AVCaptureVideoStabilizationModeCinematicExtended:
#endif
            return @"CinematicExtended";
#if TARGET_OS_VISION
        case 4:
#else
        case AVCaptureVideoStabilizationModePreviewOptimized:
#endif
            return @"PreviewOptimized";
#if TARGET_OS_VISION
        case 5:
#else
        case AVCaptureVideoStabilizationModeCinematicExtendedEnhanced:
#endif
            return @"CinematicExtendedEnhanced";
#if TARGET_OS_VISION
        case -1:
#else
        case AVCaptureVideoStabilizationModeAuto:
#endif
            return @"Auto";
        default:
            abort();
    }
}
