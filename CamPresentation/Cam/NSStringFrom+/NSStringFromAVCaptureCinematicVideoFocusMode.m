//
//  NSStringFromAVCaptureCinematicVideoFocusMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/10/25.
//

#import <CamPresentation/NSStringFromAVCaptureCinematicVideoFocusMode.h>

NSString * NSStringFromAVCaptureCinematicVideoFocusMode(AVCaptureCinematicVideoFocusMode focusMode) {
    switch (focusMode) {
        case AVCaptureCinematicVideoFocusModeNone:
            return @"None";
        case AVCaptureCinematicVideoFocusModeStrong:
            return @"Strong";
        case AVCaptureCinematicVideoFocusModeWeak:
            return @"Weak";
        default:
            abort();
    }
}
