//
//  CinematicEditTimelineCollectionViewLayoutAttributes.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicEditTimelineCollectionViewLayoutAttributes.h>

@implementation CinematicEditTimelineCollectionViewLayoutAttributes

- (instancetype)init {
    if (self = [super init]) {
        _thumbnailPresentationTime = kCMTimeInvalid;
        _thumbnailPresentationTrackID = kCMPersistentTrackID_Invalid;
    }
    
    return self;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    CinematicEditTimelineCollectionViewLayoutAttributes *copy = [super copyWithZone:zone];
    
    if (copy) {
        copy->_thumbnailPresentationTime = _thumbnailPresentationTime;
        copy->_thumbnailPresentationTrackID = _thumbnailPresentationTrackID;
    }
    
    return copy;
}

@end
