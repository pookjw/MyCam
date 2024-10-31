//
//  NSStringFromAVCaptureExposureMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <CamPresentation/NSStringFromAVCaptureExposureMode.h>

NSString * NSStringFromAVCaptureExposureMode(AVCaptureExposureMode exposureMode) {
    switch (exposureMode) {
        case AVCaptureExposureModeLocked:
            return @"Locked";
        case AVCaptureExposureModeAutoExpose:
            return @"Auto Expose";
        case AVCaptureExposureModeContinuousAutoExposure:
            return @"Continuous Auto Exposure";
        case AVCaptureExposureModeCustom:
            return @"Custom";
        default:
            abort();
    }
}
