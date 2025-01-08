//
//  NSStringFromVNRequestTextRecognitionLevel.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/8/25.
//

#import <CamPresentation/NSStringFromVNRequestTextRecognitionLevel.h>

NSString * NSStringFromVNRequestTextRecognitionLevel(VNRequestTextRecognitionLevel level) {
    switch (level) {
        case VNRequestTextRecognitionLevelAccurate:
            return @"Accurate";
        case VNRequestTextRecognitionLevelFast:
            return @"Fast";
        default:
            abort();
    }
}
