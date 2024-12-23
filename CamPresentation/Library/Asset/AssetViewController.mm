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
#import <CamPresentation/VideoPlayerListViewController.h>
#import <CamPresentation/UIDeferredMenuElement+NerualAnalyzer.h>
#import <CamPresentation/ImageVisionViewController.h>
#import <AVKit/AVKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

#warning TODO Live Photo (Vision은 Live Photo + Spatial일 수 있으며, PhotosXRUI에 해당 기능을 처리하는게 Swift로 있음)

@interface AssetViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (retain, nonatomic, readonly) PHAssetCollection *collection;
@property (retain, nonatomic, readonly) PHAsset *asset;
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) AssetsDataSource *dataSource;
@property (retain, nonatomic, readonly) UIBarButtonItem *playerBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *nerualAnalzyerBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *imageVisionBarButtonItem;
@property (assign, nonatomic) NerualAnalyzerModelType modelType;
@end

@implementation AssetViewController
@synthesize collectionView = _collectionView;
@synthesize dataSource = _dataSource;
@synthesize playerBarButtonItem = _playerBarButtonItem;
@synthesize nerualAnalzyerBarButtonItem = _nerualAnalzyerBarButtonItem;
@synthesize imageVisionBarButtonItem = _imageVisionBarButtonItem;

- (instancetype)initWithCollection:(PHAssetCollection *)collection asset:(PHAsset *)asset {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _collection = [collection retain];
        _asset = [asset retain];
        _modelType = NerualAnalyzerModelTypeCatOrDogV2;
    }
    
    return self;
}

- (void)dealloc {
    [_collection release];
    [_asset release];
    [_collectionView release];
    [_dataSource release];
    [_playerBarButtonItem release];
    [_nerualAnalzyerBarButtonItem release];
    [_imageVisionBarButtonItem release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[
        self.nerualAnalzyerBarButtonItem,
        self.playerBarButtonItem,
        self.imageVisionBarButtonItem
    ];
    
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
    
    UIBarButtonItem *playerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"play.rectangle.on.rectangle"] style:UIBarButtonItemStylePlain target:self action:@selector(didTriggerPlayerBarButtonItem:)];
    
    _playerBarButtonItem = [playerBarButtonItem retain];
    return [playerBarButtonItem autorelease];
}

- (UIBarButtonItem *)nerualAnalzyerBarButtonItem {
    if (auto nerualAnalzyerBarButtonItem = _nerualAnalzyerBarButtonItem) return nerualAnalzyerBarButtonItem;
    
    __block auto unretainedSelf = self;
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        PHAsset *asset = [unretainedSelf currentAsset];
        if (asset == nil) {
            completion(@[]);
            return;
        }
        
        UIDeferredMenuElement *element = [UIDeferredMenuElement cp_nerualAnalyzerMenuWithModelType:unretainedSelf.modelType
                                                                                             asset:asset
                                                                                  requestIDHandler:nil
                                                                         didSelectModelTypeHandler:^(NerualAnalyzerModelType modelType) {
            if (unretainedSelf.modelType == modelType) return;
            
            unretainedSelf.modelType = modelType;
            reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(unretainedSelf.nerualAnalzyerBarButtonItem, sel_registerName("_updateMenuInPlace"));
        }];
        
        completion(@[element]);
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[element]];
    
    UIBarButtonItem *nerualAnalzyerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"staroflife.fill"] menu:menu];
    
    _nerualAnalzyerBarButtonItem = [nerualAnalzyerBarButtonItem retain];
    return [nerualAnalzyerBarButtonItem autorelease];
}

- (UIBarButtonItem *)imageVisionBarButtonItem {
    if (auto imageVisionBarButtonItem = _imageVisionBarButtonItem) return imageVisionBarButtonItem;
    
    UIBarButtonItem *imageVisionBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"person.and.background.dotted"] style:UIBarButtonItemStylePlain target:self action:@selector(didTriggerImageVisionBarButtonItem:)];
    
    _imageVisionBarButtonItem = [imageVisionBarButtonItem retain];
    return [imageVisionBarButtonItem autorelease];
}

- (void)didTriggerPlayerBarButtonItem:(UIBarButtonItem *)sender {
    PHAsset *asset = [self currentVideoAsset];
    assert(asset != nil);
    VideoPlayerListViewController *viewController = [[VideoPlayerListViewController alloc] initWithAsset:asset];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (void)didTriggerImageVisionBarButtonItem:(UIBarButtonItem *)sender {
    PHAsset *asset = [self currentAsset];
    assert(asset != nil);
    
    ImageVisionViewController *rootViewController = [[ImageVisionViewController alloc] initWithAsset:asset];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    [rootViewController release];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
}

- (PHAsset * _Nullable)currentAsset {
    UICollectionView *collectionView = self.collectionView;
    
    NSIndexPath * _Nullable indexPath = [collectionView indexPathForItemAtPoint:CGPointMake(CGRectGetMidX(collectionView.bounds), CGRectGetMidY(collectionView.bounds))];
    if (indexPath == nil) {
        return nil;
    }
    
    PHAsset * _Nullable asset = [self.dataSource assetAtIndexPath:indexPath];
    return asset;
}

- (PHAsset * _Nullable)currentVideoAsset {
    PHAsset * _Nullable asset = [self currentAsset];
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
#if TARGET_OS_TV
    self.playerBarButtonItem.enabled = [self currentVideoAsset] != nil;
#else
    self.playerBarButtonItem.hidden = [self currentVideoAsset] == nil;
#endif
    
    NSLog(@"%@", [self currentAsset].localIdentifier);
}

@end
