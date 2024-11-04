//
//  AssetCollectionsViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/31/24.
//

#import <CamPresentation/AssetCollectionsViewController.h>
#import <CamPresentation/AssetsViewController.h>
#import <CamPresentation/AssetCollectionsDataSource.h>
#import <CamPresentation/AssetCollectionCell.h>
#import <CamPresentation/AssetCollectionsHeaderView.h>
#import <CamPresentation/AssetCollectionsCollectionViewLayout.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AssetCollectionsViewController () <UICollectionViewDelegate>
@property (retain, nonatomic, readonly) AssetCollectionsDataSource *dataSource;
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) UIBarButtonItem *switchLayoutBarButtonItem;
@end

@implementation AssetCollectionsViewController
@synthesize dataSource = _dataSource;
@synthesize collectionView = _collectionView;
@synthesize switchLayoutBarButtonItem = _switchLayoutBarButtonItem;

- (void)dealloc {
    [_dataSource release];
    [_collectionView release];
    [_switchLayoutBarButtonItem release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.rightBarButtonItem = self.switchLayoutBarButtonItem;
    
    [self dataSource];
}

- (AssetCollectionsDataSource *)dataSource {
    if (auto dataSource = _dataSource) return dataSource;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:AssetCollectionCell.class configurationHandler:^(AssetCollectionCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, AssetCollectionItemModel * _Nonnull item) {
        cell.model = item;
    }];
    
    __weak auto weakSelf = self;
    
    UICollectionViewSupplementaryRegistration *headerRegistration = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:AssetCollectionsHeaderView.class elementKind:UICollectionElementKindSectionHeader configurationHandler:^(AssetCollectionsHeaderView * _Nonnull supplementaryView, NSString * _Nonnull elementKind, NSIndexPath * _Nonnull indexPath) {
        if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            PHAssetCollectionType collectionType = [weakSelf.dataSource collectionTypeOfSectionIndex:indexPath.section];
            
            NSString *title;
            switch (collectionType) {
                case PHAssetCollectionTypeAlbum:
                    title = @"Albums";
                    break;
                case PHAssetCollectionTypeSmartAlbum:
                    title = @"Smart Albums";
                    break;
                default:
                    abort();
            }
            
            supplementaryView.title = title;
        } else {
            abort();
        }
    }];
    
    AssetCollectionsDataSource *dataSource = [[AssetCollectionsDataSource alloc] initWithCollectionView:self.collectionView cellRegistration:cellRegistration supplementaryRegistration:headerRegistration];
    
    _dataSource = [dataSource retain];
    return [dataSource autorelease];
}

- (UIBarButtonItem *)switchLayoutBarButtonItem {
    if (auto switchLayoutBarButtonItem = _switchLayoutBarButtonItem) return switchLayoutBarButtonItem;
    
    UIBarButtonItem *switchLayoutBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"rectangle.split.2x2"] style:UIBarButtonItemStylePlain target:self action:@selector(didTriggerSwitchLayoutBarButtonItem:)];
    
    _switchLayoutBarButtonItem = [switchLayoutBarButtonItem retain];
    return [switchLayoutBarButtonItem autorelease];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
//    __kindof UICollectionViewLayout *collectionViewLayout = [self newCollectionViewCompositionalLayout];
    __kindof UICollectionViewLayout *collectionViewLayout = [self newCustomCollectionViewLayout];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (void)didTriggerSwitchLayoutBarButtonItem:(UIBarButtonItem *)sender {
    UICollectionView *collectionView = self.collectionView;
    __kindof UICollectionViewLayout *currentLayout = collectionView.collectionViewLayout;
    
    __kindof UICollectionViewLayout *nextLayout;
    if (currentLayout.class == UICollectionViewCompositionalLayout.class) {
        nextLayout = [self newCustomCollectionViewLayout];
    } else if (currentLayout.class == AssetCollectionsCollectionViewLayout.class) {
        nextLayout = [self newCollectionViewCompositionalLayout];
    } else if (currentLayout.class == UICollectionViewTransitionLayout.class) {
        // TODO: Cancel and re-create
        return;
    } else {
        abort();
    }
    
    UICollectionViewTransitionLayout *transitionLayout = [collectionView startInteractiveTransitionToCollectionViewLayout:nextLayout completion:^(BOOL completed, BOOL finished) {
        
    }];
    
    [nextLayout release];
    
    [collectionView finishInteractiveTransition];
}

- (UICollectionViewCompositionalLayout *)newCollectionViewCompositionalLayout {
    UICollectionViewCompositionalLayoutConfiguration *configuration = [UICollectionViewCompositionalLayoutConfiguration new];
    configuration.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    UICollectionViewCompositionalLayout *collectionViewLayout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger sectionIndex, id<NSCollectionLayoutEnvironment>  _Nonnull layoutEnvironment) {
        NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.]
                                                                          heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.]];
        
        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize supplementaryItems:@[]];
        
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:200.]
                                                                           heightDimension:[NSCollectionLayoutDimension estimatedDimension:218.]];
        
        NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:@[item]];
        
        NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
        section.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehaviorContinuousGroupLeadingBoundary;
        section.interGroupSpacing = 20.;
        
        NSCollectionLayoutSize *headerSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.]
                                                                            heightDimension:[NSCollectionLayoutDimension estimatedDimension:73.5]];
        
        NSCollectionLayoutBoundarySupplementaryItem *headerItem = [NSCollectionLayoutBoundarySupplementaryItem boundarySupplementaryItemWithLayoutSize:headerSize
                                                                                                                                           elementKind:UICollectionElementKindSectionHeader
                                                                                                                                             alignment:NSRectAlignmentTopLeading
                                                                                                                                        absoluteOffset:CGPointMake(0., -20.)];
        headerItem.extendsBoundary = YES;
        headerItem.pinToVisibleBounds = YES;
        
        section.boundarySupplementaryItems = @[headerItem];
        section.contentInsets = NSDirectionalEdgeInsetsMake(0., 20., 20., 20.);
        section.supplementaryContentInsetsReference = UIContentInsetsReferenceNone;
//        section.visibleItemsInvalidationHandler = ^(NSArray<id<NSCollectionLayoutVisibleItem>> * _Nonnull visibleItems, CGPoint contentOffset, id<NSCollectionLayoutEnvironment>  _Nonnull layoutEnvironment) {
//
//        };
        
        return section;
    }
                                                                                                                       configuration:configuration];
    
    [configuration release];
    
    return collectionViewLayout;
}

- (AssetCollectionsCollectionViewLayout *)newCustomCollectionViewLayout {
    return [AssetCollectionsCollectionViewLayout new];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAssetCollection *collection = [self.dataSource collectionAtIndexPath:indexPath];
    AssetsViewController *assetsViewController = [AssetsViewController new];
    assetsViewController.collection = collection;
    [self.navigationController pushViewController:assetsViewController animated:YES];
    [assetsViewController release];
}

- (UICollectionViewTransitionLayout *)collectionView:(UICollectionView *)collectionView transitionLayoutForOldLayout:(UICollectionViewLayout *)fromLayout newLayout:(UICollectionViewLayout *)toLayout {
    return [[[UICollectionViewTransitionLayout alloc] initWithCurrentLayout:fromLayout nextLayout:toLayout] autorelease];
}

@end
