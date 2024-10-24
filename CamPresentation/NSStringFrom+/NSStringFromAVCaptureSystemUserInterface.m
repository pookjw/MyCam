//
//  NSStringFromAVCaptureSystemUserInterface.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/24/24.
//

#import <CamPresentation/NSStringFromAVCaptureSystemUserInterface.h>

NSString * NSStringFromAVCaptureSystemUserInterface(AVCaptureSystemUserInterface systemUserInterface) {
    switch (systemUserInterface) {
        case AVCaptureSystemUserInterfaceVideoEffects:
            return @"Video Effects";
        case AVCaptureSystemUserInterfaceMicrophoneModes:
            return @"Microphone Modes";
        default:
            abort();
    }
}
