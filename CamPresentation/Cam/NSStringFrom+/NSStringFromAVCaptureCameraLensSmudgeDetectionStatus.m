//
//  NSStringFromAVCaptureCameraLensSmudgeDetectionStatus.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/10/25.
//

#import <CamPresentation/NSStringFromAVCaptureCameraLensSmudgeDetectionStatus.h>

NSString * NSStringFromAVCaptureCameraLensSmudgeDetectionStatus(AVCaptureCameraLensSmudgeDetectionStatus status) {
    switch (status) {
        case AVCaptureCameraLensSmudgeDetectionStatusDisabled:
            return @"Disabled";
        case AVCaptureCameraLensSmudgeDetectionStatusSmudgeNotDetected:
            return @"Smudge Not Detected";
        case AVCaptureCameraLensSmudgeDetectionStatusSmudged:
            return @"Smudged";
        case AVCaptureCameraLensSmudgeDetectionStatusUnknown:
            return @"Unknown";
        default:
            abort();
    }
}
