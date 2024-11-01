//
//  AssetsViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetsViewController.h>
#import <CamPresentation/AssetsDataSource.h>
#import <CamPresentation/AssetCollectionViewCell.h>
#import <CamPresentation/AssetItemModel.h>
#import <CamPresentation/AssetsCollectionViewLayout.h>

@interface AssetsViewController () <UICollectionViewDelegate>
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) AssetsDataSource *dataSource;
@end

@implementation AssetsViewController
@synthesize collectionView = _collectionView;
@synthesize dataSource = _dataSource;

- (void)dealloc {
    [_collection release];
    [_collectionView release];
    [_dataSource release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setCollection:(PHAssetCollection *)collection {
    [self.dataSource updateCollection:collection];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    AssetsCollectionViewLayout *collectionViewLayout = [AssetsCollectionViewLayout new];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (AssetsDataSource *)dataSource {
    if (auto dataSource = _dataSource) return dataSource;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:AssetCollectionViewCell.class configurationHandler:^(AssetCollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, AssetItemModel * _Nonnull model) {
        cell.model = model;
    }];
    
    AssetsDataSource *dataSource = [[AssetsDataSource alloc] initWithCollectionView:self.collectionView cellRegistration:cellRegistration];
    
    _dataSource = [dataSource retain];
    return [dataSource autorelease];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"TODO");
}

@end
