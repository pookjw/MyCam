//
//  NSStringFromVNGeneratePersonSegmentationRequestQualityLevel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/23/24.
//

#import <CamPresentation/NSStringFromVNGeneratePersonSegmentationRequestQualityLevel.h>

NSString * NSStringFromVNGeneratePersonSegmentationRequestQualityLevel(VNGeneratePersonSegmentationRequestQualityLevel qualityLevel) {
    switch (qualityLevel) {
        case VNGeneratePersonSegmentationRequestQualityLevelAccurate:
            return @"Accurate";
        case VNGeneratePersonSegmentationRequestQualityLevelBalanced:
            return @"Balanced";
        case VNGeneratePersonSegmentationRequestQualityLevelFast:
            return @"Fast";
        default:
            abort();
    }
}
