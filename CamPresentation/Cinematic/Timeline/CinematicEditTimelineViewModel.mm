//
//  CinematicEditTimelineViewModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicEditTimelineViewModel.h>

@interface CinematicEditTimelineViewModel ()
@property (retain, nonatomic, readonly, getter=_parentViewModel) CinematicViewModel *parentViewModel;
@property (retain, nonatomic, readonly, getter=_dataSource) UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel * ,CinematicEditTimelineItemModel *> *dataSource;
@end

@implementation CinematicEditTimelineViewModel

- (instancetype)initWithParentViewModel:(CinematicViewModel *)parentViewModel dataSource:(UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel * ,CinematicEditTimelineItemModel *> *)dataSource {
    if (self = [super init]) {
        _parentViewModel = [parentViewModel retain];
        _dataSource = [dataSource retain];
        [parentViewModel addObserver:self forKeyPath:@"isolated_snapshot" options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    return self;
}

- (void)dealloc {
    [_parentViewModel removeObserver:self forKeyPath:@"isolated_snapshot"];
    [_parentViewModel release];
    [_dataSource release];
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

- (void)isolated_reloadDataSource {
    dispatch_assert_queue(self.parentViewModel.queue);
    
    NSDiffableDataSourceSnapshot<CinematicEditTimelineSectionModel * ,CinematicEditTimelineItemModel *> *snapshot = [NSDiffableDataSourceSnapshot new];
    
    CinematicEditTimelineSectionModel *videoTrackSectionModel = [[CinematicEditTimelineSectionModel alloc] initWithType:CinematicEditTimelineSectionModelTypeVideoTrack];
    CinematicEditTimelineSectionModel *decisionsSectionModel = [[CinematicEditTimelineSectionModel alloc] initWithType:CinematicEditTimelineSectionModelTypeDecisions];
    CinematicEditTimelineSectionModel *detectionTracksSectionModel = [[CinematicEditTimelineSectionModel alloc] initWithType:CinematicEditTimelineSectionModelTypeDetectionTracks];
    
    [snapshot appendSectionsWithIdentifiers:@[
        videoTrackSectionModel,
        decisionsSectionModel,
        detectionTracksSectionModel
    ]];
    
    CinematicSnapshot *cinematicSnapshot = self.parentViewModel.isolated_snapshot;
    
    {
        CNAssetInfo *assetInfo = cinematicSnapshot.assetData.cnAssetInfo;
        AVAssetTrack *cinematicVideoTrack = assetInfo.cinematicVideoTrack;
        [snapshot appendItemsWithIdentifiers:@[[CinematicEditTimelineItemModel videoTrackItemModelWithTrackID:cinematicVideoTrack.trackID]] intoSectionWithIdentifier:videoTrackSectionModel];
    }
    
    CNScript *script = cinematicSnapshot.assetData.cnScript;
    NSArray<CNDetectionTrack *> *addedDetectionTracks = script.addedDetectionTracks;
    
    {
        NSMutableArray<CinematicEditTimelineItemModel *> *itemModels = [[NSMutableArray alloc] initWithCapacity:addedDetectionTracks.count];
        
        for (CNDetectionTrack *detectionTrack in addedDetectionTracks) {
            [itemModels addObject:[CinematicEditTimelineItemModel detectionTrackItemModelWithDetectionTrack:detectionTrack]];
        }
        
        [snapshot appendItemsWithIdentifiers:itemModels intoSectionWithIdentifier:detectionTracksSectionModel];
        [itemModels release];
    }
    
    NSArray<CNDecision *> *decisions = [script decisionsInTimeRange:script.timeRange];
    
    {
        NSArray<CNDecision *> *sortedDecisions = [decisions sortedArrayUsingComparator:^NSComparisonResult(CNDecision * _Nonnull obj1, CNDecision * _Nonnull obj2) {
            return static_cast<NSComparisonResult>(CMTimeCompare(obj1.time, obj2.time));
        }];
        
        CMTime lastTime = kCMTimeZero;
        NSMutableArray<CinematicEditTimelineItemModel *> *itemModels = [[NSMutableArray alloc] initWithCapacity:sortedDecisions.count];
        
        for (CNDecision *decision in sortedDecisions) {
            CMTimeRange timeRange = CMTimeRangeMake(lastTime, CMTimeSubtract(decision.time, lastTime));
            CMTimeRange startTimeRange = [script timeRangeOfTransitionBeforeDecision:decision];
            CMTimeRange endTimeRange = [script timeRangeOfTransitionAfterDecision:decision];
            
            CinematicEditTimelineItemModel *itemModel = [CinematicEditTimelineItemModel decisionItemModelWithDecision:decision timeRange:timeRange startTransitionTimeRange:startTimeRange endTransitionTimeRange:endTimeRange];
            [itemModels addObject:itemModel];
        }
        
        [snapshot appendItemsWithIdentifiers:itemModels intoSectionWithIdentifier:decisionsSectionModel];
        [itemModels release];
    }
    
    [videoTrackSectionModel release];
    [detectionTracksSectionModel release];
    [decisionsSectionModel release];
    
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES];
    [snapshot release];
}

@end
