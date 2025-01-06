//
//  NSStringFromVNGenerateOpticalFlowRequestComputationAccuracy.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/6/25.
//

#import <CamPresentation/NSStringFromVNGenerateOpticalFlowRequestComputationAccuracy.h>

NSString * NSStringFromVNGenerateOpticalFlowRequestComputationAccuracy(VNGenerateOpticalFlowRequestComputationAccuracy accuracy) {
    switch (accuracy) {
        case VNGenerateOpticalFlowRequestComputationAccuracyLow:
            return @"Low";
        case VNGenerateOpticalFlowRequestComputationAccuracyMedium:
            return @"Medium";
        case VNGenerateOpticalFlowRequestComputationAccuracyHigh:
            return @"High";
        case VNGenerateOpticalFlowRequestComputationAccuracyVeryHigh:
            return @"Very High";
        default:
            abort();
    }
}
