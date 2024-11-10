//
//  AssetViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <CamPresentation/AssetViewController.h>
#import <CamPresentation/AssetsDataSource.h>
#import <CamPresentation/AssetsItemModel.h>
#import <CamPresentation/AssetCollectionViewCell.h>
#import <CamPresentation/AssetCollectionViewLayout.h>
#import <CamPresentation/PlayerViewController.h>

#warning TODO Live Photo

@interface AssetViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (retain, nonatomic, readonly) PHAssetCollection *collection;
@property (retain, nonatomic, readonly) PHAsset *asset;
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) AssetsDataSource *dataSource;
@property (retain, nonatomic, readonly) UIBarButtonItem *playerBarButtonItem;
@end

@implementation AssetViewController
@synthesize collectionView = _collectionView;
@synthesize dataSource = _dataSource;
@synthesize playerBarButtonItem = _playerBarButtonItem;

- (instancetype)initWithCollection:(PHAssetCollection *)collection asset:(PHAsset *)asset {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _collection = [collection retain];
        _asset = [asset retain];
    }
    
    return self;
}

- (void)dealloc {
    [_collection release];
    [_asset release];
    [_collectionView release];
    [_dataSource release];
    [_playerBarButtonItem release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.playerBarButtonItem;
    
    [self.dataSource updateCollection:self.collection completionHandler:^{
        NSIndexPath * _Nullable indexPath = [self.dataSource indexPathFromAsset:self.asset];
        if (indexPath == nil) return;
        
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:0 animated:NO];
    }];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (NSIndexPath *indexPath = self.collectionView.indexPathsForVisibleItems.firstObject) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:0 animated:NO];
        }
                                     completion:nil];
    }
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    AssetCollectionViewLayout *collectionViewLayout = [AssetCollectionViewLayout new];
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    collectionView.bouncesVertically = NO;
    collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (AssetsDataSource *)dataSource {
    if (auto dataSource = _dataSource) return dataSource;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:AssetCollectionViewCell.class configurationHandler:^(AssetCollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, AssetsItemModel * _Nonnull item) {
        cell.model = item;
    }];
    
    AssetsDataSource *dataSource = [[AssetsDataSource alloc] initWithCollectionView:self.collectionView cellRegistration:cellRegistration requestMaximumSize:YES];
    
    _dataSource = [dataSource retain];
    return [dataSource autorelease];
}

- (UIBarButtonItem *)playerBarButtonItem {
    if (auto playerBarButtonItem = _playerBarButtonItem) return playerBarButtonItem;
    
    UIBarButtonItem *playerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"play.rectangle"] style:UIBarButtonItemStylePlain target:self action:@selector(didTriggerPlayerBarButtonItem:)];
    
    _playerBarButtonItem = [playerBarButtonItem retain];
    return [playerBarButtonItem autorelease];
}

- (void)didTriggerPlayerBarButtonItem:(UIBarButtonItem *)sender {
    if (PHAsset *asset = [self currentVideoAsset]) {
        PlayerViewController *playerViewController = [[PlayerViewController alloc] initWithAsset:asset];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:playerViewController];
        [playerViewController release];
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navigationController animated:YES completion:nil];
        [navigationController release];
    }
}

- (PHAsset * _Nullable)currentVideoAsset {
    UICollectionView *collectionView = self.collectionView;
    
    NSIndexPath * _Nullable indexPath = [collectionView indexPathForItemAtPoint:CGPointMake(CGRectGetMidX(collectionView.bounds), CGRectGetMidY(collectionView.bounds))];
    if (indexPath == nil) {
        return nil;
    }
    
    PHAsset * _Nullable asset = [self.dataSource assetAtIndexPath:indexPath];
    if (asset == nil) {
        return nil;
    }
    
    if (asset.mediaType != PHAssetMediaTypeVideo) {
        return nil;
    }
    
    return asset;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.bounds.size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 20.;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.playerBarButtonItem.hidden = [self currentVideoAsset] == nil;
}

@end
