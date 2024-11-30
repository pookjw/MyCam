//
//  PlayerListViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/28/24.
//

#import <CamPresentation/VideoPlayerListViewController.h>
#import <CamPresentation/VideoPlayerListViewModel.h>
#import <CamPresentation/ARVideoPlayerViewController.h>
#import <CamPresentation/PlayerLayerViewController.h>
#import <CamPresentation/PlayerOutputViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

@interface VideoPlayerListViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (retain, nonatomic, readonly) VideoPlayerListViewModel *viewModel;
@property (retain, nonatomic, readonly) __kindof UIView *progressView;
@property (retain, nonatomic, readonly) UIBarButtonItem *progressBarButtonItem;
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *cellRegistration;
@end

@implementation VideoPlayerListViewController
@synthesize progressView = _progressView;
@synthesize progressBarButtonItem = _progressBarButtonItem;
@synthesize collectionView = _collectionView;
@synthesize cellRegistration = _cellRegistration;

+ (NSArray<Class> *)playerViewControllerClasses {
    return @[
        ARVideoPlayerViewController.class,
        PlayerLayerViewController.class,
        PlayerOutputViewController.class
    ];
}

- (instancetype)initWithAsset:(PHAsset *)asset {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [[VideoPlayerListViewModel alloc] initWithAsset:asset];
    }
    
    return self;
}

- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [[VideoPlayerListViewModel alloc] initWithPlayerItem:playerItem];
    }
    
    return self;
}

- (void)dealloc {
    /*
     -loadPlayerItemWithProgressHandler:이 불리는 도중에 이게 불릴 일은 없을 것.
     -loadPlayerItemWithProgressHandler:이 불리는 도중이란 것은 self가 retain 되어 있기 때문
     */
    [_viewModel cancelLoading];
    
    [_viewModel release];
    [_progressView release];
    [_progressBarButtonItem release];
    [_collectionView release];
    [_cellRegistration release];
    
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.rightBarButtonItem = self.progressBarButtonItem;
    
    __kindof UIView *progressView = self.progressView;
    UICollectionView *collectionView = self.collectionView;
    
    [self.viewModel loadPlayerItemWithProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        assert(error == nil);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            reinterpret_cast<void (*)(id, SEL, double, BOOL, id)>(objc_msgSend)(progressView, sel_registerName("setProgress:animated:completion:"), progress, YES, nil);
        });
    }
                                     comletionHandler:^{
        [collectionView reloadData];
    }];
    
    [self cellRegistration];
}

- (void)loadDataSourceWithAsset:(PHAsset *)asset {
    assert(asset != nil);
}

- (__kindof UIView *)progressView {
    if (auto progressView = _progressView) return progressView;
    
    __kindof UIView *progressView = [objc_lookUpClass("_UICircleProgressView") new];
    
    [NSLayoutConstraint activateConstraints:@[
        [progressView.widthAnchor constraintEqualToConstant:44.],
        [progressView.heightAnchor constraintEqualToConstant:44.]
    ]];
    
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(progressView, sel_registerName("setShowProgressTray:"), YES);
    
    _progressView = [progressView retain];
    return [progressView autorelease];
}

- (UIBarButtonItem *)progressBarButtonItem {
    if (auto progressBarButtonItem = _progressBarButtonItem) return progressBarButtonItem;
    
    UIBarButtonItem *progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.progressView];
    
    _progressBarButtonItem = [progressBarButtonItem retain];
    return [progressBarButtonItem autorelease];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
#if TARGET_OS_TV
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceGrouped];
#else
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
#endif
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:listConfiguration];
    [listConfiguration release];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (UICollectionViewCellRegistration *)cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, Class _Nonnull item) {
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        contentConfiguration.text = NSStringFromClass(item);
        cell.contentConfiguration = contentConfiguration;
    }];
    
    _cellRegistration = [cellRegistration retain];
    return cellRegistration;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [VideoPlayerListViewController playerViewControllerClasses].count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueConfiguredReusableCellWithRegistration:self.cellRegistration forIndexPath:indexPath item:[VideoPlayerListViewController playerViewControllerClasses][indexPath.item]];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AVPlayerItem *playerItem = self.viewModel.playerItem;
    assert(playerItem != nil);
    
    Class viewControllerClass = [VideoPlayerListViewController playerViewControllerClasses][indexPath.item];
    
    if (viewControllerClass == ARVideoPlayerViewController.class) {
        AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        ARVideoPlayerViewController *viewController = [[ARVideoPlayerViewController alloc] initWithPlayer:player];
        [player release];
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    } else if (viewControllerClass == PlayerLayerViewController.class) {
        AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        PlayerLayerViewController *viewController = [[PlayerLayerViewController alloc] initWithPlayer:player];
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            NSURL *url = [NSBundle.mainBundle URLForResource:@"demo_2" withExtension:@"mov"];
//            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:url];
//            [player replaceCurrentItemWithPlayerItem:playerItem];
//            [playerItem release];
//        });
        
        [player release];
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    } else if (viewControllerClass == PlayerOutputViewController.class) {
        AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        PlayerOutputViewController *viewController = [[PlayerOutputViewController alloc] initWithPlayer:player];
        [player release];
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    } else {
        abort();
    }
}

@end
