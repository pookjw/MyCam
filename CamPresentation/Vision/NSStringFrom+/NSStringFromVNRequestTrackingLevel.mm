//
//  NSStringFromVNRequestTrackingLevel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/10/25.
//

#import <CamPresentation/NSStringFromVNRequestTrackingLevel.h>

NSString * NSStringFromVNRequestTrackingLevel(VNRequestTrackingLevel level) {
    switch (level) {
        case VNRequestTrackingLevelAccurate:
            return @"Accurate";
        case VNRequestTrackingLevelFast:
            return @"Fast";
        default:
            abort();
    }
}
