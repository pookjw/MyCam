//
//  NSStringFromAVAudioStereoOrientation.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/17/24.
//

#import <CamPresentation/NSStringFromAVAudioStereoOrientation.h>

NSString * NSStringFromAVAudioStereoOrientation(AVAudioStereoOrientation stereoOrientation) {
    switch (stereoOrientation) {
        case AVAudioStereoOrientationNone:
            return @"None";
        case AVAudioStereoOrientationPortrait:
            return @"Portrait";
        case AVAudioStereoOrientationPortraitUpsideDown:
            return @"Portrait Upside Down";
        case AVAudioStereoOrientationLandscapeLeft:
            return @"Landscape Left";
        case AVAudioStereoOrientationLandscapeRight:
            return @"Landscape Right";
        default:
            abort();
    }
}
