//
//  NSStringFromAVCaptureSystemUserInterface.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/24/24.
//

#import <CamPresentation/NSStringFromAVCaptureSystemUserInterface.h>

#if TARGET_OS_VISION
NSString * NSStringFromAVCaptureSystemUserInterface(NSInteger systemUserInterface)
#else
NSString * NSStringFromAVCaptureSystemUserInterface(AVCaptureSystemUserInterface systemUserInterface)
#endif
{
    switch (systemUserInterface) {
#if TARGET_OS_VISION
        case 1:
#else
        case AVCaptureSystemUserInterfaceVideoEffects:
#endif
            return @"Video Effects";
#if TARGET_OS_VISION
        case 2:
#else
        case AVCaptureSystemUserInterfaceMicrophoneModes:
#endif
            return @"Microphone Modes";
        default:
            abort();
    }
}
