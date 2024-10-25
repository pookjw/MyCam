//
//  NSStringFromAVCaptureColorSpace.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/NSStringFromAVCaptureColorSpace.h>

#if TARGET_OS_VISION
NSString * NSStringFromAVCaptureColorSpace(NSInteger colorSpace)
#else
NSString * NSStringFromAVCaptureColorSpace(AVCaptureColorSpace colorSpace)
#endif
{
    switch (colorSpace) {
#if TARGET_OS_VISION
        case 0:
#else
        case AVCaptureColorSpace_sRGB:
#endif
            return @"AVCaptureColorSpace_sRGB";
#if TARGET_OS_VISION
        case 1:
#else
        case AVCaptureColorSpace_P3_D65:
#endif
            return @"AVCaptureColorSpace_P3_D65";
#if TARGET_OS_VISION
        case 2:
#else
        case AVCaptureColorSpace_HLG_BT2020:
#endif
            return @"AVCaptureColorSpace_HLG_BT2020";
#if TARGET_OS_VISION
        case 3:
#else
        case AVCaptureColorSpace_AppleLog:
#endif
            return @"AVCaptureColorSpace_AppleLog";
        default:
            abort();
    }
}
