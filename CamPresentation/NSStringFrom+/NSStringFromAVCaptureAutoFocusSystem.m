//
//  NSStringFromAVCaptureAutoFocusSystem.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/12/24.
//

#import <CamPresentation/NSStringFromAVCaptureAutoFocusSystem.h>

#if TARGET_OS_VISION
NSString * NSStringFromAVCaptureAutoFocusSystem(NSInteger focusSystem)
#else
NSString * NSStringFromAVCaptureAutoFocusSystem(AVCaptureAutoFocusSystem focusSystem)
#endif
{
    switch (focusSystem) {
#if TARGET_OS_VISION
        case 0:
#else
        case AVCaptureAutoFocusSystemNone:
#endif
            return @"None";
#if TARGET_OS_VISION
        case 1:
#else
        case AVCaptureAutoFocusSystemContrastDetection:
#endif
            return @"Contrast Detection";
#if TARGET_OS_VISION
        case 2:
#else
        case AVCaptureAutoFocusSystemPhaseDetection:
#endif
            return @"System Phase Detection";
        default:
            abort();
    }
}
