//
//  NSStringFromAVCaptureAutoFocusSystem.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/12/24.
//

#import <CamPresentation/NSStringFromAVCaptureAutoFocusSystem.h>

NSString * NSStringFromAVCaptureAutoFocusSystem(AVCaptureAutoFocusSystem focusSystem) {
    switch (focusSystem) {
        case AVCaptureAutoFocusSystemNone:
            return @"None";
        case AVCaptureAutoFocusSystemContrastDetection:
            return @"Contrast Detection";
        case AVCaptureAutoFocusSystemPhaseDetection:
            return @"System Phase Detection";
        default:
            abort();
    }
}
