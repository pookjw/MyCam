//
//  CinematicEditTimelineView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicEditTimelineView.h>
#import <CamPresentation/CinematicEditTimelineViewModel.h>
#import <CamPresentation/CinematicEditTimelineCollectionViewLayout.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/CinematicEditTimelineVideoTrackContentView.h>
#import <CamPresentation/CinematicEditTimelineDetectionsContentView.h>
#import <CamPresentation/CinematicEditTimelineDecisionContentView.h>
#import <CamPresentation/CinematicEditTimelineVideoThumbnailView.h>

__attribute__((objc_direct_members))
@interface CinematicEditTimelineView () <UICollectionViewDelegate>
@property (retain, nonatomic, readonly, getter=_viewModel) CinematicEditTimelineViewModel *viewModel;
@property (retain, nonatomic, readonly, getter=_dataSource) UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel *, CinematicEditTimelineItemModel *> *dataSource;
@property (retain, nonatomic, readonly, getter=_collectionView) UICollectionView *collectionView;
@property (nonatomic, retain, getter=_collectionViewLayout) CinematicEditTimelineCollectionViewLayout *collectionViewLayout;
@property (retain, nonatomic, readonly, getter=_videoTrackCellRegistration) UICollectionViewCellRegistration *videoTrackCellRegistration;
@property (retain, nonatomic, readonly, getter=_detectionsCellRegistration) UICollectionViewCellRegistration *detectionsCellRegistration;
@property (retain, nonatomic, readonly, getter=_decisionCellRegistration) UICollectionViewCellRegistration *decisionCellRegistration;
@property (retain, nonatomic, readonly, getter=_videoThumbnailSupplementaryRegistration) UICollectionViewSupplementaryRegistration *videoThumbnailSupplementaryRegistration;
@property (retain, nonatomic, readonly, getter=_pinchGestureRecognizer) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (assign, nonatomic, getter=_originalPixelsForSecond, setter=_setOriginalPixelsForSecond:) CGFloat originalPixelsForSecond;
@end

@implementation CinematicEditTimelineView
@synthesize dataSource = _dataSource;
@synthesize collectionView = _collectionView;
@synthesize videoTrackCellRegistration = _videoTrackCellRegistration;
@synthesize detectionsCellRegistration = _detectionsCellRegistration;
@synthesize decisionCellRegistration = _decisionCellRegistration;
@synthesize videoThumbnailSupplementaryRegistration = _videoThumbnailSupplementaryRegistration;
@synthesize pinchGestureRecognizer = _pinchGestureRecognizer;

- (instancetype)initWithParentViewModel:(CinematicViewModel *)parentViewModel {
    if (self = [super init]) {
        _viewModel = [[CinematicEditTimelineViewModel alloc] initWithParentViewModel:parentViewModel dataSource:self.dataSource];
        
        UICollectionView *collectionView = self.collectionView;
        [self addSubview:collectionView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), collectionView);
    }
    
    return self;
}

- (void)dealloc {
    [_viewModel release];
    [_dataSource release];
    [_collectionView release];
    [_videoTrackCellRegistration release];
    [_detectionsCellRegistration release];
    [_decisionCellRegistration release];
    [_videoThumbnailSupplementaryRegistration release];
    [_pinchGestureRecognizer release];
    [super dealloc];
}

- (void)scrollToTime:(CMTime)time {
    UICollectionView *collectionView = self.collectionView;
    if (collectionView.dragging) return;
    CGPoint contentOffset = [self.collectionViewLayout contentOffsetFromTime:time];
    [collectionView setContentOffset:contentOffset animated:NO];
}

- (UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel *,CinematicEditTimelineItemModel *> *)_dataSource {
    if (auto dataSource = _dataSource) return dataSource;
    
    UICollectionViewCellRegistration *videoTrackCellRegistration = self.videoTrackCellRegistration;
    UICollectionViewCellRegistration *detectionsCellRegistration = self.detectionsCellRegistration;
    UICollectionViewCellRegistration *decisionCellRegistration = self.decisionCellRegistration;
    UICollectionViewSupplementaryRegistration *videoThumbnailSupplementaryRegistration = self.videoThumbnailSupplementaryRegistration;
    
    UICollectionViewDiffableDataSource *dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, CinematicEditTimelineItemModel * _Nonnull itemModel) {
        switch (itemModel.type) {
            case CinematicEditTimelineItemModelTypeVideoTrack: {
                return [collectionView dequeueConfiguredReusableCellWithRegistration:videoTrackCellRegistration forIndexPath:indexPath item:itemModel];
                break;
            }
            case CinematicEditTimelineItemModelTypeDetections: {
                return [collectionView dequeueConfiguredReusableCellWithRegistration:detectionsCellRegistration forIndexPath:indexPath item:itemModel];
                break;
            }
            case CinematicEditTimelineItemModelTypeDecision: {
                return [collectionView dequeueConfiguredReusableCellWithRegistration:decisionCellRegistration forIndexPath:indexPath item:itemModel];
                break;
            }
            default:
                abort();
        }
    }];
    
    dataSource.supplementaryViewProvider = ^UICollectionReusableView * _Nullable(UICollectionView * _Nonnull collectionView, NSString * _Nonnull elementKind, NSIndexPath * _Nonnull indexPath) {
        if ([elementKind isEqualToString:CinematicEditTimelineCollectionViewLayoutVideoThumbnailSupplementaryElementKind]) {
            return [collectionView dequeueConfiguredReusableSupplementaryViewWithRegistration:videoThumbnailSupplementaryRegistration forIndexPath:indexPath];
        } else {
            abort();
        }
    };
    
    _dataSource = dataSource;
    return dataSource;
}

- (UICollectionView *)_collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    CinematicEditTimelineCollectionViewLayout *collectionViewLayout = [CinematicEditTimelineCollectionViewLayout new];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    
    collectionView.delegate = self;
    [collectionView addGestureRecognizer:self.pinchGestureRecognizer];
    
    _collectionView = collectionView;
    return collectionView;
}

- (CinematicEditTimelineCollectionViewLayout *)_collectionViewLayout {
    return static_cast<CinematicEditTimelineCollectionViewLayout *>(self.collectionView.collectionViewLayout);
}

- (UICollectionViewCellRegistration *)_videoTrackCellRegistration {
    if (auto videoTrackCellRegistration = _videoTrackCellRegistration) return videoTrackCellRegistration;
    
    UICollectionViewCellRegistration *videoTrackCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:[UICollectionViewCell class] configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, id  _Nonnull item) {
        CinematicEditTimelineVideoTrackContentConfiguration *contentConfiguration = [CinematicEditTimelineVideoTrackContentConfiguration new];
        cell.contentConfiguration = contentConfiguration;
        [contentConfiguration release];
    }];
    
    _videoTrackCellRegistration = [videoTrackCellRegistration retain];
    return videoTrackCellRegistration;
}

- (UICollectionViewCellRegistration *)_detectionsCellRegistration {
    if (auto detectionsCellRegistration = _detectionsCellRegistration) return detectionsCellRegistration;
    
    UICollectionViewCellRegistration *detectionsCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:[UICollectionViewCell class] configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, id  _Nonnull item) {
        CinematicEditTimelineDetectionsContentConfiguration *contentConfiguration = [CinematicEditTimelineDetectionsContentConfiguration new];
        cell.contentConfiguration = contentConfiguration;
        [contentConfiguration release];
    }];
    
    _detectionsCellRegistration = [detectionsCellRegistration retain];
    return detectionsCellRegistration;
}

- (UICollectionViewCellRegistration *)_decisionCellRegistration {
    if (auto decisionCellRegistration = _decisionCellRegistration) return decisionCellRegistration;
    
    UICollectionViewCellRegistration *decisionCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:[UICollectionViewCell class] configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, id  _Nonnull item) {
        CinematicEditTimelineDecisionContentConfiguration *contentConfiguration = [CinematicEditTimelineDecisionContentConfiguration new];
        cell.contentConfiguration = contentConfiguration;
        [contentConfiguration release];
    }];
    
    _decisionCellRegistration = [decisionCellRegistration retain];
    return decisionCellRegistration;
}

- (UICollectionViewSupplementaryRegistration *)_videoThumbnailSupplementaryRegistration {
    if (auto videoThumbnailSupplementaryRegistration = _videoThumbnailSupplementaryRegistration) return videoThumbnailSupplementaryRegistration;
    
    __block auto unretained = self;
    
    UICollectionViewSupplementaryRegistration *videoThumbnailSupplementaryRegistration = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:[CinematicEditTimelineVideoThumbnailView class] elementKind:CinematicEditTimelineCollectionViewLayoutVideoThumbnailSupplementaryElementKind configurationHandler:^(CinematicEditTimelineVideoThumbnailView * _Nonnull supplementaryView, NSString * _Nonnull elementKind, NSIndexPath * _Nonnull indexPath) {
        supplementaryView.asset = unretained.viewModel.mainQueue_cinematicSnapshot.assetData.avAsset;
    }];
    
    _videoThumbnailSupplementaryRegistration = [videoThumbnailSupplementaryRegistration retain];
    return videoThumbnailSupplementaryRegistration;
}

- (UIPinchGestureRecognizer *)_pinchGestureRecognizer {
    if (auto pinchGestureRecognizer = _pinchGestureRecognizer) return pinchGestureRecognizer;
    
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(_didTriggerPinchGestureRecognizer:)];
    
    _pinchGestureRecognizer = pinchGestureRecognizer;
    return pinchGestureRecognizer;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    id<CinematicEditTimelineViewDelegate> delegate = self.delegate;
    UICollectionView *collectionView = self.collectionView;
    
    if ((delegate != nil) and (collectionView != nil)) {
        if (collectionView.dragging or collectionView.decelerating) {
            CMTime time = [self.collectionViewLayout timeFromContentOffset:collectionView.contentOffset];
            if (CMTIME_IS_VALID(time)) {
                [delegate cinematicEditTimelineView:self didRequestSeekingTime:time];
            }
        }
    }
}

- (void)_didTriggerPinchGestureRecognizer:(UIPinchGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.originalPixelsForSecond = self.collectionViewLayout.pixelsForSecond;
    }
    
    self.collectionViewLayout.pixelsForSecond = self.originalPixelsForSecond * sender.scale;
}

@end
