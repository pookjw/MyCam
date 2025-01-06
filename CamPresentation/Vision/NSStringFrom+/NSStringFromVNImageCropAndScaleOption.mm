//
//  NSStringFromVNImageCropAndScaleOption.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/6/25.
//

#import <CamPresentation/NSStringFromVNImageCropAndScaleOption.h>

NSString * NSStringFromVNImageCropAndScaleOption(VNImageCropAndScaleOption option) {
    switch (option) {
        case VNImageCropAndScaleOptionCenterCrop:
            return @"Center Crop";
        case VNImageCropAndScaleOptionScaleFit:
            return @"Scale Fit";
        case VNImageCropAndScaleOptionScaleFill:
            return @"Scale Fill";
        case VNImageCropAndScaleOptionScaleFitRotate90CCW:
            return @"Scale Fit Rotate 90CCW";
        case VNImageCropAndScaleOptionScaleFillRotate90CCW:
            return @"Scale Fill Rotate 90CCW";
        default:
            abort();
    }
}
