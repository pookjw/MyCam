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

+ (CinematicEditTimelineItemModel *)videoTrackItemModel {
    return [[[CinematicEditTimelineItemModel alloc] _initWithType:CinematicEditTimelineItemModelTypeVideoTrack] autorelease];
}

+ (CinematicEditTimelineItemModel *)disparityTrackItemModel {
    return [[[CinematicEditTimelineItemModel alloc] _initWithType:CinematicEditTimelineItemModelTypeDisparityTrack] autorelease];
}

+ (CinematicEditTimelineItemModel *)detectionsItemModelWithDetections:(NSArray<CNDetection *> *)detections timeRange:(CMTimeRange)timeRange {
    CinematicEditTimelineItemModel *itemModel = [[CinematicEditTimelineItemModel alloc] _initWithType:CinematicEditTimelineItemModelTypeDetections];
    itemModel->_detections = [detections copy];
    assert(CMTIMERANGE_IS_VALID(timeRange));
    itemModel->_timeRange = timeRange;
    return [itemModel autorelease];
}

+ (CinematicEditTimelineItemModel *)decisionItemModelWithDecision:(CNDecision *)decision startTransitionTimeRange:(CMTimeRange)startTransitionTimeRange endTransitionTimeRange:(CMTimeRange)endTransitionTimeRange {
    CinematicEditTimelineItemModel *itemModel = [[CinematicEditTimelineItemModel alloc] _initWithType:CinematicEditTimelineItemModelTypeDecision];
    itemModel->_decision = [decision copy];
    itemModel->_startTransitionTimeRange = startTransitionTimeRange;
    itemModel->_endTransitionTimeRange = endTransitionTimeRange;
    assert(CMTIMERANGE_IS_VALID(startTransitionTimeRange));
    assert(CMTIMERANGE_IS_VALID(endTransitionTimeRange));
    CMTimeRange timeRange = CMTimeRangeMake(startTransitionTimeRange.start, CMTimeSubtract(CMTimeRangeGetEnd(endTransitionTimeRange), startTransitionTimeRange.start));
    assert(CMTIMERANGE_IS_VALID(timeRange));
    itemModel->_timeRange = timeRange;
    return [itemModel autorelease];
}

- (instancetype)_initWithType:(CinematicEditTimelineItemModelType)type {
    if (self = [super init]) {
        _type = type;
        _startTransitionTimeRange = kCMTimeRangeInvalid;
        _endTransitionTimeRange = kCMTimeRangeInvalid;
        _timeRange = kCMTimeRangeInvalid;
    }
    
    return self;
}

- (void)dealloc {
    [_detections release];
    [_decision release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    
    if (![other isKindOfClass:[CinematicEditTimelineItemModel class]]) {
        return NO;
    }
    
    auto casted = static_cast<CinematicEditTimelineItemModel *>(other);
    
    return (_type == casted->_type) and
    ([_detections isEqual:casted->_detections]) and
    ([_decision isEqual:casted->_decision]) and
    (CMTimeRangeEqual(_startTransitionTimeRange, casted->_startTransitionTimeRange)) and
    (CMTimeRangeEqual(_endTransitionTimeRange, casted->_endTransitionTimeRange)) and
    (CMTimeRangeEqual(_timeRange, casted->_timeRange));
}

- (NSUInteger)hash {
    id builder = [objc_lookUpClass("BSHashBuilder") new];
    assert(builder != nil);
    
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_type, sizeof(CinematicEditTimelineItemModelType));
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(builder, sel_registerName("appendObject:"), _detections);
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(builder, sel_registerName("appendObject:"), _decision);
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_startTransitionTimeRange, sizeof(CMTimeRange));
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_endTransitionTimeRange, sizeof(CMTimeRange));
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_timeRange, sizeof(CMTimeRange));
    
    NSUInteger hash = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(builder, @selector(hash));
    [builder release];
    
    return hash;
}

@end
