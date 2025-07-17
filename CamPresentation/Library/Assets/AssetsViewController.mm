//
//  AssetsViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetsViewController.h>
#import <CamPresentation/AssetsDataSource.h>
#import <CamPresentation/AssetsCollectionViewCell.h>
#import <CamPresentation/AssetsItemModel.h>
#import <CamPresentation/AssetsCollectionViewLayout.h>
#import <CamPresentation/AssetViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */

@interface AssetsViewController () <UICollectionViewDelegate, AssetViewControllerDelegate>
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
    
    self.navigationItem.rightBarButtonItems = @[
        self.editButtonItem
    ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.collectionView.allowsMultipleSelection) {
        reinterpret_cast<void (*)(id, SEL, id, BOOL, id)>(objc_msgSend)(self.collectionView, sel_registerName("_deselectItemsAtIndexPaths:animated:transitionCoordinator:"), self.collectionView.indexPathsForSelectedItems, animated, self.transitionCoordinator);
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    self.navigationItem.hidesBackButton = editing;
    self.collectionView.editing = editing;
}

- (void)setCollection:(PHAssetCollection *)collection {
    if ([_collection isEqual:collection]) return;
    
    _collection = [collection retain];
    [self.dataSource updateCollection:collection completionHandler:nil];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    AssetsCollectionViewLayout *collectionViewLayout = [AssetsCollectionViewLayout new];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    
    collectionView.allowsMultipleSelectionDuringEditing = YES;
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (AssetsDataSource *)dataSource {
    if (auto dataSource = _dataSource) return dataSource;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:AssetsCollectionViewCell.class configurationHandler:^(AssetsCollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, AssetsItemModel * _Nonnull model) {
        cell.model = model;
    }];
    
    AssetsDataSource *dataSource = [[AssetsDataSource alloc] initWithCollectionView:self.collectionView cellRegistration:cellRegistration requestMaximumSize:NO];
    
    _dataSource = [dataSource retain];
    return [dataSource autorelease];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) return;
    
    PHAssetCollection *collection = self.collection;
    PHAsset *asset = [self.dataSource assetAtIndexPath:indexPath];
    assert(asset != nil);
    
    AssetViewController *assetViewController = [[AssetViewController alloc] initWithCollection:collection asset:asset];
    assetViewController.delegate = self;
    [self.navigationController pushViewController:assetViewController animated:YES];
    [assetViewController release];
}

- (void)assetViewController:(AssetViewController *)assetViewController didSelectAsset:(PHAsset *)selectedAsset {
    if (id<AssetsViewControllerDelegate> delegate = self.delegate) {
        [delegate assetsViewController:self didSelectAssets:@[selectedAsset]];
    }
}

@end
