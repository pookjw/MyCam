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
#import <AVKit/AVKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/ARVideoPlayerViewController.h>

#warning TODO Live Photo (Vision은 Live Photo + Spatial일 수 있으며, PhotosXRUI에 해당 기능을 처리하는게 Swift로 있음)

@interface AssetViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (retain, nonatomic, readonly) PHAssetCollection *collection;
@property (retain, nonatomic, readonly) PHAsset *asset;
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) AssetsDataSource *dataSource;
@property (retain, nonatomic, readonly) UIBarButtonItem *arVideoPlayerBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *customPlayerBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *playerBarButtonItem;
@end

@implementation AssetViewController
@synthesize collectionView = _collectionView;
@synthesize dataSource = _dataSource;
@synthesize arVideoPlayerBarButtonItem = _arVideoPlayerBarButtonItem;
@synthesize customPlayerBarButtonItem = _customPlayerBarButtonItem;
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
    [_arVideoPlayerBarButtonItem release];
    [_customPlayerBarButtonItem release];
    [_playerBarButtonItem release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[
        self.arVideoPlayerBarButtonItem,
        self.customPlayerBarButtonItem,
        self.playerBarButtonItem
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

- (UIBarButtonItem *)arVideoPlayerBarButtonItem {
    if (auto arVideoPlayerBarButtonItem = _arVideoPlayerBarButtonItem) return arVideoPlayerBarButtonItem;
    
    UIBarButtonItem *arVideoPlayerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.3.layers.3d.top.filled"] style:UIBarButtonItemStylePlain target:self action:@selector(didTriggerARPlayerBarButtonItem:)];
    
    _arVideoPlayerBarButtonItem = [arVideoPlayerBarButtonItem retain];
    return [arVideoPlayerBarButtonItem autorelease];
}

- (UIBarButtonItem *)customPlayerBarButtonItem {
    if (auto customPlayerBarButtonItem = _customPlayerBarButtonItem) return customPlayerBarButtonItem;
    
    UIBarButtonItem *customPlayerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"play.rectangle"] style:UIBarButtonItemStylePlain target:self action:@selector(didTriggerCustomPlayerBarButtonItem:)];
    
    _customPlayerBarButtonItem = [customPlayerBarButtonItem retain];
    return [customPlayerBarButtonItem autorelease];
}

- (UIBarButtonItem *)playerBarButtonItem {
    if (auto playerBarButtonItem = _playerBarButtonItem) return playerBarButtonItem;
    
    UIBarButtonItem *playerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"play.rectangle.on.rectangle"] style:UIBarButtonItemStylePlain target:self action:@selector(didTriggerPlayerBarButtonItem:)];
    
    _playerBarButtonItem = [playerBarButtonItem retain];
    return [playerBarButtonItem autorelease];
}

- (void)didTriggerARPlayerBarButtonItem:(UIBarButtonItem *)sender {
    if (PHAsset *asset = [self currentVideoAsset]) {
        ARVideoPlayerViewController *playerViewController = [[ARVideoPlayerViewController alloc] initWithAsset:asset];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:playerViewController];
        [playerViewController release];
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navigationController animated:YES completion:nil];
        [navigationController release];
    }
}

- (void)didTriggerCustomPlayerBarButtonItem:(UIBarButtonItem *)sender {
    if (PHAsset *asset = [self currentVideoAsset]) {
        PlayerViewController *playerViewController = [[PlayerViewController alloc] initWithAsset:asset];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:playerViewController];
        [playerViewController release];
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navigationController animated:YES completion:nil];
        [navigationController release];
    }
}

- (void)didTriggerPlayerBarButtonItem:(UIBarButtonItem *)sender {
    PHAsset *asset = [self currentVideoAsset];
    if (asset == nil) return;
    
    UIViewController *progressViewController = [UIViewController new];
#if TARGET_OS_TV
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
#else
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
#endif
    progressViewController.view = progressView;
    
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    options.networkAccessAllowed = YES;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), dispatch_get_main_queue());
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressView setProgress:progress animated:YES];
        });
    };
    
    PHImageRequestID requestID = [PHImageManager.defaultManager requestPlayerItemForVideo:asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
        assert(playerItem != nil);
        
        [progressViewController dismissViewControllerAnimated:YES completion:^{
            AVPlayerViewController *playerViewController = [AVPlayerViewController new];
            AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            playerViewController.player = player;
            [player release];
            
            [self presentViewController:playerViewController animated:YES completion:nil];
            [playerViewController release];
        }];
    }];
    
    [options release];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Loading" message:asset.localIdentifier preferredStyle:UIAlertControllerStyleAlert];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(alertController, sel_registerName("setContentViewController:"), progressViewController);
    [progressViewController release];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [PHImageManager.defaultManager cancelImageRequest:requestID];
    }];
    
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
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
#if TARGET_OS_TV
    self.customPlayerBarButtonItem.enabled = [self currentVideoAsset] != nil;
#else
    self.customPlayerBarButtonItem.hidden = [self currentVideoAsset] == nil;
#endif
}

@end
