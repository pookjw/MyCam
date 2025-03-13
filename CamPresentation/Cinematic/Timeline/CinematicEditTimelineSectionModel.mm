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
    assert(trackID != kCMPersistentTrackID_Invalid);
    assert(CMTIMERANGE_IS_VALID(timeRange));
    CinematicEditTimelineSectionModel *sectionModel = [[CinematicEditTimelineSectionModel alloc] _initWithType:CinematicEditTimelineSectionModelTypeVideoTrack];
    sectionModel->_trackID = trackID;
    sectionModel->_timeRange = timeRange;
    return [sectionModel autorelease];
}

+ (CinematicEditTimelineSectionModel *)disparityTrackSectionModelWithTrackID:(CMPersistentTrackID)trackID timeRange:(CMTimeRange)timeRange {
    assert(trackID != kCMPersistentTrackID_Invalid);
    assert(CMTIMERANGE_IS_VALID(timeRange));
    CinematicEditTimelineSectionModel *sectionModel = [[CinematicEditTimelineSectionModel alloc] _initWithType:CinematicEditTimelineSectionModelTypeDisparityTrack];
    sectionModel->_trackID = trackID;
    sectionModel->_timeRange = timeRange;
    return [sectionModel autorelease];
}

+ (CinematicEditTimelineSectionModel *)detectionTrackSectionModelWithDetectionTrackID:(CNDetectionID)detectionTrackID trackID:(CMPersistentTrackID)trackID timeRange:(CMTimeRange)timeRange; {
    assert([CNDetection isValidDetectionID:detectionTrackID]);
    assert(trackID != kCMPersistentTrackID_Invalid);
    assert(CMTIMERANGE_IS_VALID(timeRange));
    CinematicEditTimelineSectionModel *sectionModel = [[CinematicEditTimelineSectionModel alloc] _initWithType:CinematicEditTimelineSectionModelTypeDetectionTrack];
    sectionModel->_detectionTrackID = detectionTrackID;
    sectionModel->_trackID = trackID;
    sectionModel->_timeRange = timeRange;
    return [sectionModel autorelease];
}

- (instancetype)_initWithType:(CinematicEditTimelineSectionModelType)type {
    if (self = [super init]) {
        _type = type;
        _trackID = kCMPersistentTrackID_Invalid;
        _detectionTrackID = reinterpret_cast<CNDetectionGroupID (*)(Class, SEL)>(objc_msgSend)([CNDetection class], sel_registerName("invalidDetectionID"));
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
    
    return (_type == casted->_type) and (_trackID == casted->_trackID) and (_detectionTrackID == casted->_detectionTrackID) and (CMTimeRangeEqual(_timeRange, casted->_timeRange));
}

- (NSUInteger)hash {
    id builder = [objc_lookUpClass("BSHashBuilder") new];
    assert(builder != nil);
    
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_type, sizeof(CinematicEditTimelineSectionModelType));
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_trackID, sizeof(CMPersistentTrackID));
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_detectionTrackID, sizeof(CNDetectionID));
    reinterpret_cast<void (*)(id, SEL, const void *, size_t)>(objc_msgSend)(builder, sel_registerName("appendBytes:length:"), &_timeRange, sizeof(CMTimeRange));
    
    NSUInteger hash = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(builder, @selector(hash));
    [builder release];
    
    return hash;
}

@end
