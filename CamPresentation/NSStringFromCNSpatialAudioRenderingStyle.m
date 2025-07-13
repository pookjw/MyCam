//
//  NSStringFromCNSpatialAudioRenderingStyle.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/12/25.
//

#import <CamPresentation/NSStringFromCNSpatialAudioRenderingStyle.h>

#if TARGET_OS_VISION || TARGET_OS_SIMULATOR

NSString * NSStringFromCNSpatialAudioRenderingStyle(NSInteger style) {
    switch (style) {
        case 0:
            return @"Cinematic";
        case 1:
            return @"Studio";
        case 2:
            return @"In Frame";
        case 3:
            return @"Cinematic Background Stem";
        case 4:
            return @"Cinematic Foreground Stem";
        case 5:
            return @"Studio Foreground Stem";
        case 6:
            return @"In Frame Foreground Stem";
        case 7:
            return @"Standard";
        case 8:
            return @"Studio Background Stem";
        case 9:
            return @"In Frame Background Stem";
        default:
            abort();
    }
}

NSInteger CNSpatialAudioRenderingStyleFromString(NSString *string) {
    if ([string isEqualToString:@"Cinematic"]) {
        return 0;
    } else if ([string isEqualToString:@"Studio"]) {
        return 1;
    } else if ([string isEqualToString:@"In Frame"]) {
        return 2;
    } else if ([string isEqualToString:@"Cinematic Background Stem"]) {
        return 3;
    } else if ([string isEqualToString:@"Cinematic Foreground Stem"]) {
        return 4;
    } else if ([string isEqualToString:@"Studio Foreground Stem"]) {
        return 5;
    } else if ([string isEqualToString:@"In Frame Foreground Stem"]) {
        return 6;
    } else if ([string isEqualToString:@"Standard"]) {
        return 7;
    } else if ([string isEqualToString:@"Studio Background Stem"]) {
        return 8;
    } else if ([string isEqualToString:@"In Frame Background Stem"]) {
        return 9;
    } else {
        abort();
    }
}

const NSInteger * allCNSpatialAudioRenderingStyles(NSUInteger * _Nullable count) {
    static const NSInteger values[] = {
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9
    };
    if (count != NULL) {
        *count = sizeof(values) / sizeof(NSInteger);
    }
    return values;
}


#else

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

#endif
