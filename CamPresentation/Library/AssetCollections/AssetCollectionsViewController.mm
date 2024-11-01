//
//  AssetCollectionsViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/31/24.
//

#import <CamPresentation/AssetCollectionsViewController.h>
#import <CamPresentation/AssetsViewController.h>
#import <CamPresentation/AssetCollectionsDataSource.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AssetCollectionsViewController () <UICollectionViewDelegate>
@property (retain, nonatomic, readonly) AssetCollectionsDataSource *dataSource;
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@end

@implementation AssetCollectionsViewController
@synthesize dataSource = _dataSource;
@synthesize collectionView = _collectionView;

- (void)dealloc {
    [_dataSource release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    [self dataSource];
}

- (AssetCollectionsDataSource *)dataSource {
    if (auto dataSource = _dataSource) return dataSource;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, PHAssetCollection * _Nonnull item) {
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        contentConfiguration.text = item.localizedTitle;
        cell.contentConfiguration = contentConfiguration;
    }];
    
    AssetCollectionsDataSource *dataSource = [[AssetCollectionsDataSource alloc] initWithCollectionView:self.collectionView cellRegistration:cellRegistration];
    
    _dataSource = [dataSource retain];
    return [dataSource autorelease];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:listConfiguration];
    [listConfiguration release];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAssetCollection *collection = [self.dataSource collectionAtIndexPath:indexPath];
    AssetsViewController *assetsViewController = [AssetsViewController new];
    assetsViewController.collection = collection;
    [self.navigationController pushViewController:assetsViewController animated:YES];
    [assetsViewController release];
}

@end
