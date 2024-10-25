//
//  NSStringFromAVCaptureAutoFocusRangeRestriction.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/12/24.
//

#import <CamPresentation/NSStringFromAVCaptureAutoFocusRangeRestriction.h>

#if TARGET_OS_VISION
NSString * NSStringFromAVCaptureAutoFocusRangeRestriction(NSInteger autoFocusRangeRestriction)
#else
NSString * NSStringFromAVCaptureAutoFocusRangeRestriction(AVCaptureAutoFocusRangeRestriction autoFocusRangeRestriction)
#endif
{
    switch (autoFocusRangeRestriction) {
#if TARGET_OS_VISION
        case 0:
#else
        case AVCaptureAutoFocusRangeRestrictionNone:
#endif
            return @"None";
#if TARGET_OS_VISION
        case 1:
#else
        case AVCaptureAutoFocusRangeRestrictionNear:
#endif
            return @"Restriction Near";
#if TARGET_OS_VISION
        case 2:
#else
        case AVCaptureAutoFocusRangeRestrictionFar:
#endif
            return @"Restriction Far";
        default:
            abort();
    }
}
