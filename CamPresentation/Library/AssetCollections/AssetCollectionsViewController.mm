//
//  AssetCollectionsViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/31/24.
//

#import <CamPresentation/AssetCollectionsViewController.h>
#import <CamPresentation/AssetsViewController.h>
#import <CamPresentation/AssetCollectionsDataSource.h>
#import <CamPresentation/AssetCollectionsCell.h>
#import <CamPresentation/AssetCollectionsHeaderView.h>
#import <CamPresentation/AssetCollectionsCollectionViewLayout.h>
#import <CamPresentation/AssetViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/MyCompositionalLayout.h>
#import <CamPresentation/ImageVisionViewController.h>
#import <CamPresentation/VideoPlayerListViewController.h>
#include <random>

@interface AssetCollectionsViewController () <UICollectionViewDelegate, AssetsViewControllerDelegate>
@property (retain, nonatomic, readonly) AssetCollectionsDataSource *dataSource;
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) UIBarButtonItem *switchLayoutBarButtonItem;
@property (retain, nonatomic, readonly) UIButton *tmpButton;
@end

@implementation AssetCollectionsViewController
@synthesize dataSource = _dataSource;
@synthesize collectionView = _collectionView;
@synthesize switchLayoutBarButtonItem = _switchLayoutBarButtonItem;
@synthesize tmpButton = _tmpButton;

- (void)dealloc {
    [_dataSource release];
    [_collectionView release];
    [_switchLayoutBarButtonItem release];
    [_tmpButton release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if !TARGET_OS_TV
    self.view.backgroundColor = UIColor.systemBackgroundColor;
#endif
    
    self.navigationItem.rightBarButtonItem = self.switchLayoutBarButtonItem;
    
    [self dataSource];
    
    self.navigationItem.titleView = self.tmpButton;
    
    if (self.presentingViewController == nil) {
        [self didTriggerTmpButton:nil];
    }
}

- (AssetCollectionsDataSource *)dataSource {
    if (auto dataSource = _dataSource) return dataSource;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:AssetCollectionsCell.class configurationHandler:^(AssetCollectionsCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, AssetCollectionsItemModel * _Nonnull item) {
        cell.model = item;
    }];
    
    UICollectionViewSupplementaryRegistration *headerRegistration = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:AssetCollectionsHeaderView.class elementKind:UICollectionElementKindSectionHeader configurationHandler:^(AssetCollectionsHeaderView * _Nonnull supplementaryView, NSString * _Nonnull elementKind, NSIndexPath * _Nonnull indexPath) {
        UICollectionView * _Nullable collectionView = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(supplementaryView, sel_registerName("_collectionView"));
        assert(collectionView != nil);
        
        auto dataSource = static_cast<AssetCollectionsDataSource *>(collectionView.dataSource);
        assert(dataSource != nil);
        assert([dataSource isKindOfClass:AssetCollectionsDataSource.class]);
        
        if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            PHAssetCollectionType collectionType = [dataSource collectionTypeOfSectionIndex:indexPath.section];
            
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
    
    UICollectionViewCompositionalLayout *collectionViewLayout = [[MyCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger sectionIndex, id<NSCollectionLayoutEnvironment>  _Nonnull layoutEnvironment) {
        NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.]
                                                                          heightDimension:[NSCollectionLayoutDimension estimatedDimension:100.]];
        
        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize supplementaryItems:@[]];
        
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:200.]
                                                                           heightDimension:[NSCollectionLayoutDimension estimatedDimension:100.]];
        
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

- (UIButton *)tmpButton {
    if (auto tmpButton = _tmpButton) return tmpButton;
    
    UIButton *tmpButton = [UIButton new];
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.title = @"TMP";
    tmpButton.configuration = configuration;
    
    [tmpButton addTarget:self action:@selector(didTriggerTmpButton:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    _tmpButton = [tmpButton retain];
    return [tmpButton autorelease];
}

- (void)didTriggerTmpButton:(UIButton *)sender {
    // PHAssetCollectionSubtypeSmartAlbumSpatial PHAssetCollectionSubtypeSmartAlbumVideos
//    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumSpatial options:nil];
//    PHAssetCollection *collection = collections.firstObject;
//    assert(collection != nil);
//    
//    PHFetchOptions *options = [PHFetchOptions new];
//    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeVideo];
//    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
//    [options release];
//    
//    if (assets.count == 0) return;
//    
//    std::random_device rd;
//    std::mt19937 gen(rd());
//    std::uniform_int_distribution<NSUInteger> distr(0, assets.count - 1);
//    
//    PHAsset *asset = assets[distr(gen)];
//    assert(asset != nil);
//    
//    AssetViewController *viewController = [[AssetViewController alloc] initWithCollection:collection asset:asset];
//    [self.navigationController pushViewController:viewController animated:YES];
//    [viewController release];
    
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[@"034A45B6-89BC-4ECB-9A75-9A77D32509D7/L0/001"] options:nil][0];
    ImageVisionViewController *viewController = [ImageVisionViewController new];
    [viewController updateWithAsset:asset];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [viewController release];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
    
//    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[@"921040DB-1932-4B9D-81A0-84DBED8169A5/L0/001"] options:nil][0];
//    VideoPlayerListViewController *viewController = [[VideoPlayerListViewController alloc] initWithAsset:asset];
//    [self.navigationController pushViewController:viewController animated:YES];
//    [viewController release];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAssetCollection *collection = [self.dataSource collectionAtIndexPath:indexPath];
    AssetsViewController *assetsViewController = [AssetsViewController new];
    assetsViewController.delegate = self;
    assetsViewController.collection = collection;
    [self.navigationController pushViewController:assetsViewController animated:YES];
    [assetsViewController release];
}

- (UICollectionViewTransitionLayout *)collectionView:(UICollectionView *)collectionView transitionLayoutForOldLayout:(UICollectionViewLayout *)fromLayout newLayout:(UICollectionViewLayout *)toLayout {
    return [[[UICollectionViewTransitionLayout alloc] initWithCurrentLayout:fromLayout nextLayout:toLayout] autorelease];
}

- (void)assetsViewController:(AssetsViewController *)assetsViewController didSelectAssets:(NSSet<PHAsset *> *)selectedAssets {
    if (id<AssetCollectionsViewControllerDelegate> delegate = self.delegate) {
        [delegate assetCollectionsViewController:self didSelectAssets:selectedAssets];
    }
}

@end
