//
//  NSStringFromVNTrackOpticalFlowRequestComputationAccuracy.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/6/25.
//

#import <CamPresentation/NSStringFromVNTrackOpticalFlowRequestComputationAccuracy.h>

NSString * NSStringFromVNTrackOpticalFlowRequestComputationAccuracy(VNTrackOpticalFlowRequestComputationAccuracy accuracy) {
    switch (accuracy) {
        case VNTrackOpticalFlowRequestComputationAccuracyLow:
            return @"Low";
        case VNTrackOpticalFlowRequestComputationAccuracyMedium:
            return @"Medium";
        case VNTrackOpticalFlowRequestComputationAccuracyHigh:
            return @"High";
        case VNTrackOpticalFlowRequestComputationAccuracyVeryHigh:
            return @"Very High";
        default:
            abort();
    }
}
