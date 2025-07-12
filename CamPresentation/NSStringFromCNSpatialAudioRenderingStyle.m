//
//  NSStringFromCNSpatialAudioRenderingStyle.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/12/25.
//

#import <CamPresentation/NSStringFromCNSpatialAudioRenderingStyle.h>

NSString * NSStringFromCNSpatialAudioRenderingStyle(CNSpatialAudioRenderingStyle style) {
    switch (style) {
        case CNSpatialAudioRenderingStyleCinematic:
            return @"Cinematic";
        case CNSpatialAudioRenderingStyleStudio:
            return @"Studio";
        case CNSpatialAudioRenderingStyleInFrame:
            return @"In Frame";
        case CNSpatialAudioRenderingStyleCinematicBackgroundStem:
            return @"Cinematic Background Stem";
        case CNSpatialAudioRenderingStyleCinematicForegroundStem:
            return @"Cinematic Foreground Stem";
        case CNSpatialAudioRenderingStyleStudioForegroundStem:
            return @"Studio Foreground Stem";
        case CNSpatialAudioRenderingStyleInFrameForegroundStem:
            return @"In Frame Foreground Stem";
        case CNSpatialAudioRenderingStyleStandard:
            return @"Standard";
        case CNSpatialAudioRenderingStyleStudioBackgroundStem:
            return @"Studio Background Stem";
        case CNSpatialAudioRenderingStyleInFrameBackgroundStem:
            return @"In Frame Background Stem";
        default:
            abort();
    }
}

CNSpatialAudioRenderingStyle CNSpatialAudioRenderingStyleFromString(NSString *string) {
    if ([string isEqualToString:@"Cinematic"]) {
        return CNSpatialAudioRenderingStyleCinematic;
    } else if ([string isEqualToString:@"Studio"]) {
        return CNSpatialAudioRenderingStyleStudio;
    } else if ([string isEqualToString:@"In Frame"]) {
        return CNSpatialAudioRenderingStyleInFrame;
    } else if ([string isEqualToString:@"Cinematic Background Stem"]) {
        return CNSpatialAudioRenderingStyleCinematicBackgroundStem;
    } else if ([string isEqualToString:@"Cinematic Foreground Stem"]) {
        return CNSpatialAudioRenderingStyleCinematicForegroundStem;
    } else if ([string isEqualToString:@"Studio Foreground Stem"]) {
        return CNSpatialAudioRenderingStyleStudioForegroundStem;
    } else if ([string isEqualToString:@"In Frame Foreground Stem"]) {
        return CNSpatialAudioRenderingStyleInFrameForegroundStem;
    } else if ([string isEqualToString:@"Standard"]) {
        return CNSpatialAudioRenderingStyleStandard;
    } else if ([string isEqualToString:@"Studio Background Stem"]) {
        return CNSpatialAudioRenderingStyleStudioBackgroundStem;
    } else if ([string isEqualToString:@"In Frame Background Stem"]) {
        return CNSpatialAudioRenderingStyleInFrameBackgroundStem;
    } else {
        abort();
    }
}

const CNSpatialAudioRenderingStyle * allCNSpatialAudioRenderingStyles(NSUInteger * _Nullable count) {
    static const CNSpatialAudioRenderingStyle values[] = {
        CNSpatialAudioRenderingStyleCinematic,
        CNSpatialAudioRenderingStyleStudio,
        CNSpatialAudioRenderingStyleInFrame,
        CNSpatialAudioRenderingStyleCinematicBackgroundStem,
        CNSpatialAudioRenderingStyleCinematicForegroundStem,
        CNSpatialAudioRenderingStyleStudioForegroundStem,
        CNSpatialAudioRenderingStyleInFrameForegroundStem,
        CNSpatialAudioRenderingStyleStandard,
        CNSpatialAudioRenderingStyleStudioBackgroundStem,
        CNSpatialAudioRenderingStyleInFrameBackgroundStem
    };
    if (count != NULL) {
        *count = sizeof(values) / sizeof(CNSpatialAudioRenderingStyle);
    }
    return values;
}
