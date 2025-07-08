//
//  NSStringFromAVCaptureMultichannelAudioMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/9/25.
//

#import <CamPresentation/NSStringFromAVCaptureMultichannelAudioMode.h>

NSString * NSStringFromAVCaptureMultichannelAudioMode(AVCaptureMultichannelAudioMode mode) {
    switch (mode) {
        case AVCaptureMultichannelAudioModeNone:
            return @"None";
        case AVCaptureMultichannelAudioModeStereo:
            return @"Stereo";
        case AVCaptureMultichannelAudioModeFirstOrderAmbisonics:
            return @"First Order Ambisonics";
        default:
            break;
    }
}
