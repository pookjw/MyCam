//
//  CinematicEditTimelineCollectionViewLayoutAttributes.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicEditTimelineCollectionViewLayoutAttributes.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <objc/message.h>
#import <objc/runtime.h>

@implementation CinematicEditTimelineCollectionViewLayoutAttributes

- (instancetype)init {
    if (self = [super init]) {
        _thumbnailPresentationTime = kCMTimeInvalid;
        _thumbnailPresentationTrackID = kCMPersistentTrackID_Invalid;
        _thumbnailPresentationDetectionTrackID = reinterpret_cast<CNDetectionID (*)(Class, SEL)>(objc_msgSend)([CNDetection class], sel_registerName("invalidDetectionID"));
    }
    
    return self;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    CinematicEditTimelineCollectionViewLayoutAttributes *copy = [super copyWithZone:zone];
    
    if (copy) {
        copy->_thumbnailPresentationTime = _thumbnailPresentationTime;
        copy->_thumbnailPresentationTrackID = _thumbnailPresentationTrackID;
        copy->_thumbnailPresentationDetectionTrackID = _thumbnailPresentationDetectionTrackID;
    }
    
    return copy;
}

@end

#endif
