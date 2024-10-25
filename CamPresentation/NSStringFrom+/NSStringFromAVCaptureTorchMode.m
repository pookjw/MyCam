//
//  NSStringFromAVCaptureTorchMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/23/24.
//

#import <CamPresentation/NSStringFromAVCaptureTorchMode.h>

#if TARGET_OS_VISION
NSString * NSStringFromAVCaptureTorchMode(NSInteger torchMode)
#else
NSString * NSStringFromAVCaptureTorchMode(AVCaptureTorchMode torchMode)
#endif
{
    switch (torchMode) {
#if TARGET_OS_VISION
        case 0:
#else
        case AVCaptureTorchModeOff:
#endif
            return @"Off";
#if TARGET_OS_VISION
        case 1:
#else
        case AVCaptureTorchModeOn:
#endif
            return @"On";
#if TARGET_OS_VISION
        case 2:
#else
        case AVCaptureTorchModeAuto:
#endif
            return @"Auto";
        default:
            abort();
    }
}
