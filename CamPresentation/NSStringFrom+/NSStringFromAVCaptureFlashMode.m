//
//  NSStringFromAVCaptureFlashMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/23/24.
//

#import <CamPresentation/NSStringFromAVCaptureFlashMode.h>

#if TARGET_OS_VISION
NSString * NSStringFromAVCaptureFlashMode(NSInteger captureFlashMode)
#else
NSString * NSStringFromAVCaptureFlashMode(AVCaptureFlashMode captureFlashMode)
#endif
{
    switch (captureFlashMode) {
#if TARGET_OS_VISION
        case 0:
#else
        case AVCaptureFlashModeOff:
#endif
            return @"Off";
#if TARGET_OS_VISION
        case 1:
#else
        case AVCaptureFlashModeOn:
#endif
            return @"On";
#if TARGET_OS_VISION
        case 2:
#else
        case AVCaptureFlashModeAuto:
#endif
            return @"Auto";
        default:
            abort();
    }
}
