//
//  CinematicEditTimelineViewModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicEditTimelineViewModel.h>

@interface CinematicEditTimelineViewModel ()
@property (retain, nonatomic, nullable, setter=_mainQueue_setCinematicSnapshot:) CinematicSnapshot *mainQueue_cinematicSnapshot;
@property (retain, nonatomic, readonly, getter=_parentViewModel) CinematicViewModel *parentViewModel;
@property (retain, nonatomic, readonly, getter=_dataSource) UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel * ,CinematicEditTimelineItemModel *> *dataSource;
@end

@implementation CinematicEditTimelineViewModel

- (instancetype)initWithParentViewModel:(CinematicViewModel *)parentViewModel dataSource:(UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel * ,CinematicEditTimelineItemModel *> *)dataSource {
    if (self = [super init]) {
        _parentViewModel = [parentViewModel retain];
        _dataSource = [dataSource retain];
        [parentViewModel addObserver:self forKeyPath:@"isolated_snapshot" options:NSKeyValueObservingOptionNew context:NULL];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didUpateScript:) name:CinematicViewModelDidUpdateScriptNotification object:parentViewModel];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_parentViewModel removeObserver:self forKeyPath:@"isolated_snapshot"];
    [_parentViewModel release];
    [_dataSource release];
    [_mainQueue_cinematicSnapshot release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.parentViewModel]) {
        if ([keyPath isEqualToString:@"isolated_snapshot"]) {
            [self _didChangeSnapshot];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)_didChangeSnapshot {
    dispatch_async(self.parentViewModel.queue, ^{
        [self isolated_reloadDataSource];
    });
}

- (void)_didUpateScript:(NSNotification *)notification {
    dispatch_async(self.parentViewModel.queue, ^{
        [self isolated_reloadDataSource];
    });
}

- (void)isolated_reloadDataSource {
    dispatch_assert_queue(self.parentViewModel.queue);
    CinematicSnapshot *cinematicSnapshot = self.parentViewModel.isolated_snapshot;
    if (cinematicSnapshot == nil) {
        NSDiffableDataSourceSnapshot<CinematicEditTimelineSectionModel * ,CinematicEditTimelineItemModel *> *snapshot = [NSDiffableDataSourceSnapshot new];
        [self.dataSource applySnapshotUsingReloadData:snapshot];
        [snapshot release];
        return;
    }
    
    AVAssetTrack *cinematicVideoTrack = cinematicSnapshot.assetData.cnAssetInfo.cinematicVideoTrack;
    AVAssetTrack *cinematicDisparityTrack = cinematicSnapshot.assetData.cnAssetInfo.cinematicDisparityTrack;
    
    NSDiffableDataSourceSnapshot<CinematicEditTimelineSectionModel * ,CinematicEditTimelineItemModel *> *snapshot = [NSDiffableDataSourceSnapshot new];
    
    {
        CinematicEditTimelineSectionModel *sectionModel = [CinematicEditTimelineSectionModel videoTrackSectionModelWithTrackID:cinematicVideoTrack.trackID timeRange:cinematicVideoTrack.timeRange];
        [snapshot appendSectionsWithIdentifiers:@[sectionModel]];
        
        CinematicEditTimelineItemModel *itemModel = [CinematicEditTimelineItemModel videoTrackItemModel];
        [snapshot appendItemsWithIdentifiers:@[itemModel] intoSectionWithIdentifier:sectionModel];
    }
    
    {
        CinematicEditTimelineSectionModel *sectionModel = [CinematicEditTimelineSectionModel disparityTrackSectionModelWithTrackID:cinematicDisparityTrack.trackID timeRange:cinematicDisparityTrack.timeRange];
        [snapshot appendSectionsWithIdentifiers:@[sectionModel]];
        
        CinematicEditTimelineItemModel *itemModel = [CinematicEditTimelineItemModel disparityTrackItemModel];
        [snapshot appendItemsWithIdentifiers:@[itemModel] intoSectionWithIdentifier:sectionModel];
    }
    
    {
        NSArray<CNDetectionTrack *> *addedDetectionTracks = cinematicSnapshot.assetData.cnScript.addedDetectionTracks;
        CMTimeRange scriptTimeRange = cinematicSnapshot.assetData.cnScript.timeRange;
        NSArray<CNDecision *> *decisions = [cinematicSnapshot.assetData.cnScript decisionsInTimeRange:scriptTimeRange];
        
        for (CNDetectionTrack *detectionTrack in addedDetectionTracks) {
            assert([CNDetection isValidDetectionID:detectionTrack.detectionID]);
            
            NSMutableDictionary<NSNumber *, NSMutableArray<CNDetection *> *> *detectionsByID = [NSMutableDictionary new];
            NSArray<CNDetection *> *detections = [detectionTrack detectionsInTimeRange:scriptTimeRange];
            for (CNDetection *detection in detections) {
                assert([CNDetection isValidDetectionID:detection.detectionID]);
                NSMutableArray<CNDetection *> *_detections = detectionsByID[@(detection.detectionID)];
                if (_detections == nil) {
                    _detections = [NSMutableArray array];
                    detectionsByID[@(detection.detectionID)] = _detections;
                }
                
                [_detections addObject:detection];
            }
            
            for (NSMutableArray<CNDetection *> *_detections in detectionsByID.allValues) {
                [_detections sortUsingComparator:^NSComparisonResult(CNDetection *  _Nonnull obj1, CNDetection * _Nonnull obj2) {
                    return static_cast<NSComparisonResult>(CMTimeCompare(obj1.time, obj2.time));
                }];
            }
            
            __block CMTime trackStartTime = kCMTimeInvalid;
            __block CMTime trackEndTime = kCMTimeInvalid;
            NSMutableDictionary<NSNumber *, NSValue *> *timeRangesByDetectionID = [NSMutableDictionary new];
            [detectionsByID enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull detectionIDNumber, NSMutableArray<CNDetection *> * _Nonnull detections, BOOL * _Nonnull stop) {
                NSUInteger count = detections.count;
                assert(count > 0);
                CMTime start = detections[0].time;
                CMTime end = detections[count - 1].time;
                NSValue *value = [NSValue valueWithCMTimeRange:CMTimeRangeMake(start, CMTimeSubtract(end, start))];
                timeRangesByDetectionID[detectionIDNumber] = value;
                
                if (CMTIME_IS_INVALID(trackStartTime)) {
                    trackStartTime = start;
                } else {
                    if (CMTimeCompare(start, trackStartTime) == -1) {
                        trackStartTime = start;
                    }
                }
                
                if (CMTIME_IS_INVALID(trackEndTime)) {
                    trackEndTime = end;
                } else {
                    if (CMTimeCompare(end, trackEndTime) == 1) {
                        trackEndTime = end;
                    }
                }
            }];
            
            CMTimeShow(trackStartTime);
            CMTimeShow(trackEndTime);
            
            assert(detectionsByID.count == timeRangesByDetectionID.count);
            
            NSMutableArray<CinematicEditTimelineItemModel *> *itemModels = [[NSMutableArray alloc] initWithCapacity:detectionsByID.count /* Decision 추가하면 더 많아질 것 */];
            [detectionsByID enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull detectionIDNumber, NSMutableArray<CNDetection *> * _Nonnull detections, BOOL * _Nonnull stop) {
                NSValue *timeRangeValue = timeRangesByDetectionID[detectionIDNumber];
                assert(timeRangeValue != nil);
                
                CinematicEditTimelineItemModel *detectionItemModel = [CinematicEditTimelineItemModel detectionsItemModelWithDetections:detections timeRange:timeRangeValue.CMTimeRangeValue];
                [itemModels addObject:detectionItemModel];
            }];
            [detectionsByID release];
            [timeRangesByDetectionID release];
            
            for (CNDecision *decision in decisions) {
                if (decision.detectionGroupID != detectionTrack.detectionGroupID) continue;
                
                BOOL found = NO;
                for (CNDetection *detection in detections) {
                    if (decision.detectionID == detection.detectionID) {
                        found = YES;
                        break;
                    }
                }
                if (!found) continue;
                
                CMTimeRange startTransitionTimeRange = [cinematicSnapshot.assetData.cnScript timeRangeOfTransitionBeforeDecision:decision];
                assert(CMTIMERANGE_IS_VALID(startTransitionTimeRange));
                CMTimeRange endTransitionTimeRange = [cinematicSnapshot.assetData.cnScript timeRangeOfTransitionAfterDecision:decision];
                assert(CMTIMERANGE_IS_VALID(endTransitionTimeRange));
                
                CinematicEditTimelineItemModel *itemModel = [CinematicEditTimelineItemModel decisionItemModelWithDecision:decision startTransitionTimeRange:startTransitionTimeRange endTransitionTimeRange:endTransitionTimeRange];
                [itemModels addObject:itemModel];
            }
            
            CinematicEditTimelineSectionModel *sectionModel = [CinematicEditTimelineSectionModel detectionTrackSectionModelWithDetectionTrackID:detectionTrack.detectionID trackID:cinematicVideoTrack.trackID timeRange:CMTimeRangeFromTimeToTime(trackStartTime, trackEndTime)];
            
            [snapshot appendSectionsWithIdentifiers:@[sectionModel]];
            [snapshot appendItemsWithIdentifiers:itemModels intoSectionWithIdentifier:sectionModel];
            [itemModels release];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mainQueue_cinematicSnapshot = cinematicSnapshot;
        [self.dataSource applySnapshot:snapshot animatingDifferences:YES];
    });
    [snapshot release];
}

@end
