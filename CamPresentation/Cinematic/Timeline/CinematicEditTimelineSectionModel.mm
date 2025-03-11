//
//  CinematicEditTimelineSectionModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicEditTimelineSectionModel.h>
#import <objc/message.h>
#import <objc/runtime.h>

@implementation CinematicEditTimelineSectionModel

+ (CinematicEditTimelineSectionModel *)videoTrackSectionModelWithTrackID:(CMPersistentTrackID)trackID timeRange:(CMTimeRange)timeRange {
    assert(CMTIMERANGE_IS_VALID(timeRange));
    CinematicEditTimelineSectionModel *sectionModel = [[CinematicEditTimelineSectionModel alloc] _initWithType:CinematicEditTimelineSectionModelTypeVideoTrack];
    sectionModel->_trackID = trackID;
    sectionModel->_timeRange = timeRange;
    return [sectionModel autorelease];
}

+ (CinematicEditTimelineSectionModel *)detectionTrackSectionModelWithDetectionTrack:(CNDetectionTrack *)detectionTrack timeRange:(CMTimeRange)timeRange {
    assert(CMTIMERANGE_IS_VALID(timeRange));
    CinematicEditTimelineSectionModel *sectionModel = [[CinematicEditTimelineSectionModel alloc] _initWithType:CinematicEditTimelineSectionModelTypeDetectionTrack];
    sectionModel->_detectionTrack = [detectionTrack copy];
    sectionModel->_timeRange = timeRange;
    return [sectionModel autorelease];
}

- (instancetype)_initWithType:(CinematicEditTimelineSectionModelType)type {
    if (self = [super init]) {
        _type = type;
        _trackID = kCMPersistentTrackID_Invalid;
        _timeRange = kCMTimeRangeInvalid;
    }
    
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    
    if (![other isKindOfClass:[CinematicEditTimelineSectionModel class]]) {
        return NO;
    }
    
    auto casted = static_cast<CinematicEditTimelineSectionModel *>(other);
    
    return (_type == casted->_type) and (_trackID == casted->_trackID) and ([_detectionTrack isEqual:casted->_detectionTrack]) and (CMTimeRangeEqual(_timeRange, casted->_timeRange));
}

- (NSUInteger)hash {
    id builder = [objc_lookUpClass("BSHashBuilder") new];
    assert(builder != nil);
    
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_type, sizeof(CinematicEditTimelineSectionModelType));
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_trackID, sizeof(CMPersistentTrackID));
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(builder, sel_registerName("appendObject:"), _detectionTrack);
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_timeRange, sizeof(CMTimeRange));
    
    NSUInteger hash = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(builder, @selector(hash));
    [builder release];
    
    return hash;
}

@end
