//
//  NSStringFromCNSpatialAudioRenderingStyle.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/12/25.
//

#import <Cinematic/Cinematic.h>
#import <CamPresentation/Extern.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSString * NSStringFromCNSpatialAudioRenderingStyle(CNSpatialAudioRenderingStyle style) API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
CP_EXTERN CNSpatialAudioRenderingStyle CNSpatialAudioRenderingStyleFromString(NSString *string) API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
CP_EXTERN const CNSpatialAudioRenderingStyle * allCNSpatialAudioRenderingStyles(NSUInteger * _Nullable count) API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));

NS_ASSUME_NONNULL_END
