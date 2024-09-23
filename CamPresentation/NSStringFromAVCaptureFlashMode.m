//
//  NSStringFromAVCaptureFlashMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/23/24.
//

#import <CamPresentation/NSStringFromAVCaptureFlashMode.h>

NSString * NSStringFromAVCaptureFlashMode(AVCaptureFlashMode captureFlashMode) {
    switch (captureFlashMode) {
        case AVCaptureFlashModeOff:
            return @"Off";
        case AVCaptureFlashModeOn:
            return @"On";
        case AVCaptureFlashModeAuto:
            return @"Auto";
        default:
            return @"";
    }
}
