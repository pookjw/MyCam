//
//  NSStringFromAVCaptureTorchMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/23/24.
//

#import "NSStringFromAVCaptureTorchMode.h"

NSString * NSStringFromAVCaptureTorchMode(AVCaptureTorchMode torchMode) {
    switch (torchMode) {
        case AVCaptureTorchModeOff:
            return @"Off";
        case AVCaptureTorchModeOn:
            return @"On";
        case AVCaptureTorchModeAuto:
            return @"Auto";
        default:
            return @"";
    }
}
