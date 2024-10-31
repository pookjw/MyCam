//
//  NSStringFromAVCaptureSessionInterruptionReason.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <CamPresentation/NSStringFromAVCaptureSessionInterruptionReason.h>

NSString * NSStringFromAVCaptureSessionInterruptionReason(AVCaptureSessionInterruptionReason reason) {
    switch (reason) {
        case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableInBackground:
            return @"Video Device Not Available In Background";
        case AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient:
            return @"Audio Device In Use By Another Client";
        case AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient:
            return @"Video Device Iny Use By Another Client";
        case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps:
            return @"Video Device Not Available With Multiple Foreground Apps";
        case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableDueToSystemPressure:
            return @"Video Device Not Available Due To System Pressure";
        default:
            abort();
    }
}
