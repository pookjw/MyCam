//
//  NSStringFromAVCaptureFocusMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/12/24.
//

#import <CamPresentation/NSStringFromAVCaptureFocusMode.h>

#if TARGET_OS_VISION
NSString * NSStringFromAVCaptureFocusMode(NSInteger focusMode)
#else
NSString * NSStringFromAVCaptureFocusMode(AVCaptureFocusMode focusMode)
#endif
{
    switch (focusMode) {
#if TARGET_OS_VISION
        case 0:
#else
        case AVCaptureFocusModeLocked:
#endif
            return @"Locked";
#if TARGET_OS_VISION
        case 1:
#else
        case AVCaptureFocusModeAutoFocus:
#endif
            return @"Auto Focus";
#if TARGET_OS_VISION
        case 2:
#else
        case AVCaptureFocusModeContinuousAutoFocus:
#endif
            return @"Continuous Auto Focus";
        default:
            abort();
    }
}
