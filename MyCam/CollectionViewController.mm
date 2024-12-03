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

@interface CollectionViewController ()
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
        VideoPlayerListViewController.class
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
    
    NSURL *url = [NSBundle.mainBundle URLForResource:@"demo_4" withExtension:UTTypeQuickTimeMovie.preferredFilenameExtension];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:url];
    VideoPlayerListViewController *viewController = [[VideoPlayerListViewController alloc] initWithPlayerItem:playerItem];
    [playerItem release];
    [self.navigationController pushViewController:viewController animated:NO];
    [viewController release];
    
//    CameraRootViewController *viewController = [CameraRootViewController new];
//    [self.navigationController pushViewController:viewController animated:YES];
//    [viewController release];
    
//    AssetCollectionsViewController *viewController = [AssetCollectionsViewController new];
//    [self.navigationController pushViewController:viewController animated:YES];
//    [viewController release];
    
//#if TARGET_OS_VISION
//    XRCamRootViewController *cameraRootViewController = [XRCamRootViewController new];
//#else
//    CameraRootViewController *cameraRootViewController = [CameraRootViewController new];
//#endif
//    [self.navigationController pushViewController:cameraRootViewController animated:YES];
//    [cameraRootViewController release];
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
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

@end
