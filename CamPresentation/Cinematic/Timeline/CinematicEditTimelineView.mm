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

@interface CinematicEditTimelineView () <UICollectionViewDelegate>
@property (retain, nonatomic, readonly, getter=_viewModel) CinematicEditTimelineViewModel *viewModel;
@property (retain, nonatomic, readonly, getter=_dataSource) UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel *, CinematicEditTimelineItemModel *> *dataSource;
@property (retain, nonatomic, readonly, getter=_collectionView) UICollectionView *collectionView;
@property (retain, nonatomic, readonly, getter=_cellRegistration) UICollectionViewCellRegistration *cellRegistration;
@end

@implementation CinematicEditTimelineView
@synthesize dataSource = _dataSource;
@synthesize collectionView = _collectionView;
@synthesize cellRegistration = _cellRegistration;

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
    [_cellRegistration release];
    [super dealloc];
}

- (UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel *,CinematicEditTimelineItemModel *> *)_dataSource {
    if (auto dataSource = _dataSource) return dataSource;
    
    UICollectionViewCellRegistration *cellRegistration = self.cellRegistration;
    
    UICollectionViewDiffableDataSource *dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, id  _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    _dataSource = dataSource;
    return dataSource;
}

- (UICollectionView *)_collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    CinematicEditTimelineCollectionViewLayout *collectionViewLayout = [CinematicEditTimelineCollectionViewLayout new];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    
    collectionView.delegate = self;
    
    _collectionView = collectionView;
    return collectionView;
}

- (UICollectionViewCellRegistration *)_cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    __block auto unretainedSelf = self;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:[UICollectionViewCell class] configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, id  _Nonnull item) {
        
    }];
    
    _cellRegistration = [cellRegistration retain];
    return cellRegistration;
}

@end
