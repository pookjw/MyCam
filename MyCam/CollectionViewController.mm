//
//  CollectionViewController.mm
//  MyCam
//
//  Created by Jinwoo Kim on 10/31/24.
//

#import "CollectionViewController.h"
#import <CamPresentation/CamPresentation.h>
#import <TargetConditionals.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <CamPresentation/AuthorizationsService.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface CollectionViewController () <AssetCollectionsViewControllerDelegate>
@property (class, nonatomic, readonly) NSArray<Class> *viewControllerClasses;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *cellRegistration;
@end

@implementation CollectionViewController
@synthesize cellRegistration = _cellRegistration;

+ (NSArray<Class> *)viewControllerClasses {
    return @[
#if TARGET_OS_VISION
        XRCamRootViewController.class,
#else
        CameraRootViewController.class,
#endif
        AssetCollectionsViewController.class,
        VideoPlayerListViewController.class,
        VisionKitDemoViewController.class
    ];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
#if TARGET_OS_TV
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceGrouped];
#else
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
#endif
    
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:listConfiguration];
    [listConfiguration release];
    
    if (self = [super initWithCollectionViewLayout:collectionViewLayout]) {
        
    }
    
    return self;
}

- (void)dealloc {
    [_cellRegistration release];
    [super dealloc];
}

- (UICollectionViewCellRegistration *)cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    NSArray<Class> *viewControllerClasses = CollectionViewController.viewControllerClasses;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, id  _Nonnull item) {
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        contentConfiguration.text = NSStringFromClass(viewControllerClasses[indexPath.item]);
        cell.contentConfiguration = contentConfiguration;
        
        UICellAccessoryDisclosureIndicator *accessory = [UICellAccessoryDisclosureIndicator new];
        cell.accessories = @[accessory];
        [accessory release];
    }];
    
    _cellRegistration = [cellRegistration retain];
    return cellRegistration;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self cellRegistration];
    
    AuthorizationsService *authorizationsService = [AuthorizationsService new];
    
    [authorizationsService requestAuthorizationsWithCompletionHandler:^(BOOL authorized) {
        if (!authorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view.window.windowScene openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:nil completionHandler:^(BOOL success) {
                    exit(EXIT_FAILURE);
                }];
            });
        }
    }];
    
    [authorizationsService release];
    
    //
    
//    NSURL *url_3 = [NSBundle.mainBundle URLForResource:@"demo_3" withExtension:UTTypeQuickTimeMovie.preferredFilenameExtension];
//    NSURL *url_4 = [NSBundle.mainBundle URLForResource:@"demo_4" withExtension:UTTypeQuickTimeMovie.preferredFilenameExtension];
//    NSURL *url_5 = [NSBundle.mainBundle URLForResource:@"demo_5" withExtension:UTTypeQuickTimeMovie.preferredFilenameExtension];
//    AVPlayerItem *playerItem_3 = [[AVPlayerItem alloc] initWithURL:url_3];
//    AVPlayerItem *playerItem_4 = [[AVPlayerItem alloc] initWithURL:url_4];
//    AVPlayerItem *playerItem_5 = [[AVPlayerItem alloc] initWithURL:url_5];
//    AVPlayerItem *playerItem_4_2 = [[AVPlayerItem alloc] initWithURL:url_4];
//    AVQueuePlayer *player = [[AVQueuePlayer alloc] initWithItems:@[playerItem_5]];
//    [playerItem_3 release];
//    [playerItem_4 release];
//    [playerItem_5 release];
//    [playerItem_4_2 release];
//    VideoPlayerListViewController *viewController = [[VideoPlayerListViewController alloc] initWithPlayer:player];
//    [player release];
//    [self.navigationController pushViewController:viewController animated:NO];
//    [viewController release];
    
    AssetCollectionsViewController *viewController = [AssetCollectionsViewController new];
    viewController.delegate = self;
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
    
//#if TARGET_OS_VISION
//    XRCamRootViewController *cameraRootViewController = [XRCamRootViewController new];
//#else
//    CameraRootViewController *cameraRootViewController = [CameraRootViewController new];
//#endif
//    [self.navigationController pushViewController:cameraRootViewController animated:YES];
//    [cameraRootViewController release];
    
//    VisionKitDemoViewController *viewController = [VisionKitDemoViewController new];
//    [self.navigationController pushViewController:viewController animated:YES];
//    [viewController release];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return CollectionViewController.viewControllerClasses.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueConfiguredReusableCellWithRegistration:self.cellRegistration forIndexPath:indexPath item:[NSNull null]];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Class viewControllerClass = [CollectionViewController viewControllerClasses][indexPath.item];
    
    if (viewControllerClass == VideoPlayerListViewController.class) {
        NSURL *url = [NSBundle.mainBundle URLForResource:@"demo_1" withExtension:UTTypeQuickTimeMovie.preferredFilenameExtension];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:url];
        VideoPlayerListViewController *viewController = [[VideoPlayerListViewController alloc] initWithPlayerItem:playerItem];
        [playerItem release];
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
        return;
    }
    
    __kindof UIViewController *viewController = [CollectionViewController.viewControllerClasses[indexPath.item] new];
    
    if ([viewController isKindOfClass:[AssetCollectionsViewController class]]) {
        auto casted = static_cast<AssetCollectionsViewController *>(viewController);
        casted.delegate = self;
    }
    
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (void)assetCollectionsViewController:(AssetCollectionsViewController *)assetCollectionsViewController didSelectAssets:(NSSet<PHAsset *> *)selectedAssets {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
