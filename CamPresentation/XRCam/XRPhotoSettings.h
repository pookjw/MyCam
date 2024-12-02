//
//  XRPhotoSettings.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/2/24.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(visionos(1.0))
@interface XRPhotoSettings : NSObject <NSCopying, NSMutableCopying> {
    @package BOOL _shutterSoundSuppressionEnabled;
}
@property (assign, nonatomic, readonly, getter=isShutterSoundSuppressionEnabled) BOOL shutterSoundSuppressionEnabled;
@end

API_AVAILABLE(visionos(1.0))
@interface MutableXRPhotoSettings: XRPhotoSettings
@property (assign, nonatomic, getter=isShutterSoundSuppressionEnabled) BOOL shutterSoundSuppressionEnabled;
@end

NS_ASSUME_NONNULL_END
