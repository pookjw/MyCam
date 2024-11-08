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

@interface AssetViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (retain, nonatomic, readonly) PHAssetCollection *collection;
@property (retain, nonatomic, readonly) PHAsset *asset;
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) AssetsDataSource *dataSource;
@end

@implementation AssetViewController
@synthesize collectionView = _collectionView;
@synthesize dataSource = _dataSource;

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
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.dataSource updateCollection:self.collection];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.bounds.size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 20.;
}

@end
