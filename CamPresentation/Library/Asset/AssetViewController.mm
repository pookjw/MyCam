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

@interface AssetViewController () <UICollectionViewDelegate>
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
    
    UICollectionViewCompositionalLayoutConfiguration *configuration = [UICollectionViewCompositionalLayoutConfiguration new];
    configuration.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    UICollectionViewCompositionalLayout *collectionViewLayout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger sectionIndex, id<NSCollectionLayoutEnvironment>  _Nonnull layoutEnvironment) {
        NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.]
                                                                          heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.]];
        
        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize supplementaryItems:@[]];
        
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.]
                                                                           heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.]];
        
        NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:@[item]];
        
        NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
        section.contentInsetsReference = UIContentInsetsReferenceNone;
        section.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehaviorGroupPaging;
        
        return section;
    }
                                                                                                                       configuration:configuration];
    [configuration release];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    collectionView.bouncesVertically = NO;
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

@end
