//
//  NSStringFromAVCaptureVideoStabilizationMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/9/24.
//

#import <CamPresentation/NSStringFromAVCaptureVideoStabilizationMode.h>

NSString * NSStringFromAVCaptureVideoStabilizationMode(AVCaptureVideoStabilizationMode videoStabilizationMode) {
    switch (videoStabilizationMode) {
        case AVCaptureVideoStabilizationModeOff:
            return @"Off";
        case AVCaptureVideoStabilizationModeStandard:
            return @"Standard";
        case AVCaptureVideoStabilizationModeCinematic:
            return @"Cinematic";
        case AVCaptureVideoStabilizationModeCinematicExtended:
            return @"CinematicExtended";
        case AVCaptureVideoStabilizationModePreviewOptimized:
            return @"PreviewOptimized";
        case AVCaptureVideoStabilizationModeCinematicExtendedEnhanced:
            return @"CinematicExtendedEnhanced";
        case AVCaptureVideoStabilizationModeAuto:
            return @"Auto";
        default:
            abort();
    }
}
