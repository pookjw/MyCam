//
//  NSStringFromAVCaptureColorSpace.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/NSStringFromAVCaptureColorSpace.h>

NSString * NSStringFromAVCaptureColorSpace(AVCaptureColorSpace colorSpace) {
    switch (colorSpace) {
        case AVCaptureColorSpace_sRGB:
            return @"AVCaptureColorSpace_sRGB";
        case AVCaptureColorSpace_P3_D65:
            return @"AVCaptureColorSpace_P3_D65";
        case AVCaptureColorSpace_HLG_BT2020:
            return @"AVCaptureColorSpace_HLG_BT2020";
        case AVCaptureColorSpace_AppleLog:
            return @"AVCaptureColorSpace_AppleLog";
        default:
            return @"";
    }
}
