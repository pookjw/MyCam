//
//  NSStringFromAVAudioSessionRouteChangeReason.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/16/24.
//

#import <CamPresentation/NSStringFromAVAudioSessionRouteChangeReason.h>

NSString * NSStringFromAVAudioSessionRouteChangeReason(AVAudioSessionRouteChangeReason routeChangeReason) {
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonUnknown:
            return @"Unknown";
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            return @"New Device Available";
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            return @"Old Device Unavailable";
        case AVAudioSessionRouteChangeReasonCategoryChange:
            return @"Category Change";
        case AVAudioSessionRouteChangeReasonOverride:
            return @"Override";
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            return @"Wake From Sleep";
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            return @"No Suitable Route For Category";
        case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
            return @"Route Configuration Change";
        default:
            abort();
    }
}
