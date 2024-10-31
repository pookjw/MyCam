//
//  NSStringFromAVCaptureAutoFocusRangeRestriction.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/12/24.
//

#import <CamPresentation/NSStringFromAVCaptureAutoFocusRangeRestriction.h>

NSString * NSStringFromAVCaptureAutoFocusRangeRestriction(AVCaptureAutoFocusRangeRestriction autoFocusRangeRestriction) {
    switch (autoFocusRangeRestriction) {
        case AVCaptureAutoFocusRangeRestrictionNone:
            return @"None";
        case AVCaptureAutoFocusRangeRestrictionNear:
            return @"Restriction Near";
        case AVCaptureAutoFocusRangeRestrictionFar:
            return @"Restriction Far";
        default:
            abort();
    }
}
