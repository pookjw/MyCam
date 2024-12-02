//
//  XRPhotoSettings.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/2/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/XRPhotoSettings.h>

@implementation XRPhotoSettings

- (id)copyWithZone:(struct _NSZone *)zone {
    XRPhotoSettings *copy = [[XRPhotoSettings allocWithZone: zone] init];
    
    if (copy) {
        copy->_shutterSoundSuppressionEnabled = _shutterSoundSuppressionEnabled;
    }
    
    return copy;
}

- (id)mutableCopyWithZone:(struct _NSZone *)zone {
    MutableXRPhotoSettings *mutableCopy = [[MutableXRPhotoSettings allocWithZone:zone] init];
    
    if (mutableCopy) {
        mutableCopy->_shutterSoundSuppressionEnabled = _shutterSoundSuppressionEnabled;
    }
    
    return mutableCopy;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else {
        auto casted = static_cast<XRPhotoSettings *>(other);
        return _shutterSoundSuppressionEnabled == casted->_shutterSoundSuppressionEnabled;
    }
}

- (NSUInteger)hash {
    return _shutterSoundSuppressionEnabled;
}

@end


@implementation MutableXRPhotoSettings

- (void)setShutterSoundSuppressionEnabled:(BOOL)shutterSoundSuppressionEnabled {
    _shutterSoundSuppressionEnabled = shutterSoundSuppressionEnabled;
}

@end

#endif
