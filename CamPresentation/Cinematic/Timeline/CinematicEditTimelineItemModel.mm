//
//  CinematicEditTimelineItemModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicEditTimelineItemModel.h>
#import <objc/message.h>
#import <objc/runtime.h>

@implementation CinematicEditTimelineItemModel

+ (CinematicEditTimelineItemModel *)videoTrackItemModelWithTrackID:(CMPersistentTrackID)trackID timeRange:(CMTimeRange)timeRange {
    CinematicEditTimelineItemModel *itemModel = [[CinematicEditTimelineItemModel alloc] _initWithType:CinematicEditTimelineItemModelTypeVideoTrack];
    itemModel->_trackID = trackID;
    itemModel->_trackTimeRange = timeRange;
    return [itemModel autorelease];
}

+ (CinematicEditTimelineItemModel *)detectionTrackItemModelWithDetectionTrack:(CNDetectionTrack *)detectionTrack {
    CinematicEditTimelineItemModel *itemModel = [[CinematicEditTimelineItemModel alloc] _initWithType:CinematicEditTimelineItemModelTypeDetectionTrack];
    itemModel->_detectionTrack = [detectionTrack copy];;
    return [itemModel autorelease];
}

+ (CinematicEditTimelineItemModel *)decisionItemModelWithDecision:(CNDecision *)decision timeRange:(CMTimeRange)timeRange startTransitionTimeRange:(CMTimeRange)startTransitionTimeRange endTransitionTimeRange:(CMTimeRange)endTransitionTimeRange {
    CinematicEditTimelineItemModel *itemModel = [[CinematicEditTimelineItemModel alloc] _initWithType:CinematicEditTimelineItemModelTypeDecision];
    itemModel->_decision = [decision copy];
    itemModel->_decisionTimeRange = timeRange;
    itemModel->_startTransitionTimeRange = startTransitionTimeRange;
    itemModel->_endTransitionTimeRange = endTransitionTimeRange;
    return [itemModel autorelease];
}

- (instancetype)_initWithType:(CinematicEditTimelineItemModelType)type {
    if (self = [super init]) {
        _type = type;
        _trackID = kCMPersistentTrackID_Invalid;
        _trackTimeRange = kCMTimeRangeInvalid;
        _decisionTimeRange = kCMTimeRangeInvalid;
        _startTransitionTimeRange = kCMTimeRangeInvalid;
        _endTransitionTimeRange = kCMTimeRangeInvalid;
    }
    
    return self;
}

- (void)dealloc {
    [_decision release];
    [_detectionTrack release];
    [super dealloc];
}

#warning TODO
- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    
    if (![other isKindOfClass:[CinematicEditTimelineItemModel class]]) {
        return NO;
    }
    
    auto casted = static_cast<CinematicEditTimelineItemModel *>(other);
    
    return (_type == casted->_type) and (_trackID == casted->_trackID) and (CMTimeRangeEqual(_trackTimeRange, casted->_trackTimeRange)) and ([_detectionTrack isEqual:casted->_detectionTrack]) and ([_decision isEqual:casted->_decision]) and (CMTimeRangeEqual(_decisionTimeRange, casted->_decisionTimeRange));
}

- (NSUInteger)hash {
    id builder = [objc_lookUpClass("BSHashBuilder") new];
    assert(builder != nil);
    
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_trackID, sizeof(CMPersistentTrackID));
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(builder, sel_registerName("appendObject:"), _detectionTrack);
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(builder, sel_registerName("appendObject:"), _decision);
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_decisionTimeRange, sizeof(CMTimeRange));
    
    NSUInteger hash = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(builder, @selector(hash));
    [builder release];
    
    return hash;
}

@end
