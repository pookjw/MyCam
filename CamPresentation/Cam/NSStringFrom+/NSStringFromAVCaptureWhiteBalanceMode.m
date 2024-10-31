//
//  NSStringFromAVCaptureWhiteBalanceMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/26/24.
//

#import <CamPresentation/NSStringFromAVCaptureWhiteBalanceMode.h>

NSString * NSStringFromAVCaptureWhiteBalanceMode(AVCaptureWhiteBalanceMode whiteBalanceMode) {
    switch (whiteBalanceMode) {
        case AVCaptureWhiteBalanceModeLocked:
            return @"Locked";
        case AVCaptureWhiteBalanceModeAutoWhiteBalance:
            return @"Auto White Balance";
        case AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance:
            return @"Continuous Auto White Balance";
        default:
            abort();
    }
}
