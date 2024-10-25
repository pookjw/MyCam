//
//  NSStringFromAVCapturePhotoQualityPrioritization.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/23/24.
//

#import <CamPresentation/NSStringFromAVCapturePhotoQualityPrioritization.h>

#if TARGET_OS_VISION
NSString * NSStringFromAVCapturePhotoQualityPrioritization(NSInteger photoQualityPrioritization)
#else
NSString * NSStringFromAVCapturePhotoQualityPrioritization(AVCapturePhotoQualityPrioritization photoQualityPrioritization)
#endif
{
    switch (photoQualityPrioritization) {
#if TARGET_OS_VISION
        case 1:
#else
        case AVCapturePhotoQualityPrioritizationSpeed:
#endif
            return @"Speed";
#if TARGET_OS_VISION
        case 2:
#else
        case AVCapturePhotoQualityPrioritizationBalanced:
#endif
            return @"Balanced";
#if TARGET_OS_VISION
        case 3:
#else
        case AVCapturePhotoQualityPrioritizationQuality:
#endif
            return @"Quality";
        default:
            abort();
    }
}
