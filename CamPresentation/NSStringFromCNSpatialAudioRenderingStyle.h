//
//  NSStringFromCNSpatialAudioRenderingStyle.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/12/25.
//

#import <Foundation/Foundation.h>
#import <CamPresentation/Extern.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION && !TARGET_OS_SIMULATOR
#import <Cinematic/Cinematic.h>
#endif


NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_VISION || TARGET_OS_SIMULATOR

CP_EXTERN NSString * NSStringFromCNSpatialAudioRenderingStyle(NSInteger style) API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0), visionos(26.0));
CP_EXTERN NSInteger CNSpatialAudioRenderingStyleFromString(NSString *string) API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0), visionos(26.0));
CP_EXTERN const NSInteger * allCNSpatialAudioRenderingStyles(NSUInteger * _Nullable count) API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0), visionos(26.0));

#else

CP_EXTERN NSString * NSStringFromCNSpatialAudioRenderingStyle(CNSpatialAudioRenderingStyle style) API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0), visionos(26.0));
CP_EXTERN CNSpatialAudioRenderingStyle CNSpatialAudioRenderingStyleFromString(NSString *string) API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0), visionos(26.0));
CP_EXTERN const CNSpatialAudioRenderingStyle * allCNSpatialAudioRenderingStyles(NSUInteger * _Nullable count) API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0), visionos(26.0));

#endif

NS_ASSUME_NONNULL_END
