//
//  NSStringFromAVCapturePhotoQualityPrioritization.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/23/24.
//

#import <CamPresentation/NSStringFromAVCapturePhotoQualityPrioritization.h>

NSString * NSStringFromAVCapturePhotoQualityPrioritization(AVCapturePhotoQualityPrioritization photoQualityPrioritization) {
    switch (photoQualityPrioritization) {
        case AVCapturePhotoQualityPrioritizationSpeed:
            return @"Speed";
        case AVCapturePhotoQualityPrioritizationBalanced:
            return @"Balanced";
        case AVCapturePhotoQualityPrioritizationQuality:
            return @"Quality";
        default:
            return @"";
    }
}
