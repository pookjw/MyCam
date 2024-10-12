//
//  NSStringFromAVCaptureFocusMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/12/24.
//

#import <CamPresentation/NSStringFromAVCaptureFocusMode.h>

NSString * NSStringFromAVCaptureFocusMode(AVCaptureFocusMode focusMode) {
    switch (focusMode) {
        case AVCaptureFocusModeLocked:
            return @"Locked";
        case AVCaptureFocusModeAutoFocus:
            return @"Auto Focus";
        case AVCaptureFocusModeContinuousAutoFocus:
            return @"Continuous Auto Focus";
        default:
            abort();
    }
}
