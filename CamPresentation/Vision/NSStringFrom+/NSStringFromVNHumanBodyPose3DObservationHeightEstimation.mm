//
//  NSStringFromVNHumanBodyPose3DObservationHeightEstimation.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/2/25.
//

#import <CamPresentation/NSStringFromVNHumanBodyPose3DObservationHeightEstimation.h>

NSString * NSStringFromVNHumanBodyPose3DObservationHeightEstimation(VNHumanBodyPose3DObservationHeightEstimation estimation) {
    switch (estimation) {
        case VNHumanBodyPose3DObservationHeightEstimationReference:
            return @"Reference";
        case VNHumanBodyPose3DObservationHeightEstimationMeasured:
            return @"Measured";
        default:
            abort();
    }
}
