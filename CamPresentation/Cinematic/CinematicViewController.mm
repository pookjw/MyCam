//
//  CinematicViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicViewController.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <CamPresentation/AssetCollectionsViewController.h>
#import <CamPresentation/CinematicViewModel.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/CinematicAssetData.h>
#import <CamPresentation/CinematicEditViewController.h>

@interface CinematicViewController () <AssetCollectionsViewControllerDelegate>
@property (retain, nonatomic, readonly, getter=_editViewController) CinematicEditViewController *editViewController;
@property (retain, nonatomic, readonly, getter=_assetPickerBarButtonItem) UIBarButtonItem *assetPickerBarButtonItem;
@property (retain, nonatomic, readonly, getter=_viewModel) CinematicViewModel *viewModel;
@property (retain, nonatomic, getter=_progress, setter=_setProgress:) NSProgress *progress;
@property (retain, nonatomic, readonly, getter=_debugBarButtonItem) UIBarButtonItem *debugBarButtonItem;
@end

@implementation CinematicViewController
@synthesize editViewController = _editViewController;
@synthesize assetPickerBarButtonItem = _assetPickerBarButtonItem;
@synthesize viewModel = _viewModel;
@synthesize progress = _progress;
@synthesize debugBarButtonItem = _debugBarButtonItem;

- (void)dealloc {
    [_editViewController release];
    [_assetPickerBarButtonItem release];
    [_viewModel release];
    
    if (NSProgress *progress = _progress) {
        [self _removeObserverForProgress:progress];
        [progress cancel];
        [progress release];
    }
    
    [_debugBarButtonItem release];
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (([keyPath isEqualToString:@"cancelled"] or [keyPath isEqualToString:@"finished"]) and [object isKindOfClass:[NSProgress class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _dismissPresentedAlertControllerForProgress:object];
            self.progress = nil;
        });
        
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CinematicEditViewController *editViewController = self.editViewController;
    [self addChildViewController:editViewController];
    [self.view addSubview:editViewController.view];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self.view, sel_registerName("_addBoundsMatchingConstraintsForView:"), editViewController.view);
    [editViewController didMoveToParentViewController:self];
    
    UINavigationItem *navigationItem = self.navigationItem;
#if TARGET_OS_TV
    navigationItem.rightBarButtonItems = @[
        self.assetPickerBarButtonItem,
        self.debugBarButtonItem
    ];
#else
    navigationItem.style = UINavigationItemStyleEditor;
    navigationItem.trailingItemGroups = @[
        [UIBarButtonItemGroup fixedGroupWithRepresentativeItem:nil items:@[
            self.assetPickerBarButtonItem,
            self.debugBarButtonItem
        ]]
    ];
#endif
    
    {
        /*
         3C146A2B-21CD-4739-A975-0AC6A2CA1777/L0/001
         437FFB47-3FE3-4EC6-8D14-C8FB9A1B8DF1/L0/001
         63216E3C-D521-4F30-8F1F-5E6E7EEEE0FD/L0/001
         0AAFD5FE-6EBB-4C6B-BEA6-A6D661292519/L0/001
         */
        PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[@"437FFB47-3FE3-4EC6-8D14-C8FB9A1B8DF1/L0/001"] options:nil];
        [self _loadWithPHAsset:assets[0]];
    }
}

- (CinematicEditViewController *)_editViewController {
    if (auto editViewController = _editViewController) return editViewController;
    
    CinematicEditViewController *editViewController = [[CinematicEditViewController alloc] initWithViewModel:self.viewModel];
    
    _editViewController = editViewController;
    return editViewController;
}

- (UIBarButtonItem *)_assetPickerBarButtonItem {
    if (auto assetPickerBarButtonItem = _assetPickerBarButtonItem) return assetPickerBarButtonItem;
    
    UIBarButtonItem *assetPickerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"photo"] style:UIBarButtonItemStylePlain target:self action:@selector(_didTriggerAssetPickerBarButtonItem:)];
    
    _assetPickerBarButtonItem = assetPickerBarButtonItem;
    return assetPickerBarButtonItem;
}

- (CinematicViewModel *)_viewModel {
    dispatch_assert_queue(dispatch_get_main_queue());
    if (auto viewModel = _viewModel) return viewModel;
    
    CinematicViewModel *viewModel = [CinematicViewModel new];
    
    _viewModel = viewModel;
    return viewModel;
}

- (UIBarButtonItem *)_debugBarButtonItem {
    if (auto debugBarButtonItem = _debugBarButtonItem) return debugBarButtonItem;
    
    UIBarButtonItem *debugBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ant.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(_didTriggerDebugBarButtonItem:)];
    
    _debugBarButtonItem = debugBarButtonItem;
    return debugBarButtonItem;
}

- (void)_addObserverForProgress:(NSProgress *)progress {
    [progress addObserver:self forKeyPath:@"cancelled" options:NSKeyValueObservingOptionNew context:NULL];
    [progress addObserver:self forKeyPath:@"finished" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)_removeObserverForProgress:(NSProgress *)progress {
    [progress removeObserver:self forKeyPath:@"cancelled"];
    [progress removeObserver:self forKeyPath:@"finished"];
}

- (void)_didTriggerAssetPickerBarButtonItem:(UIBarButtonItem *)sender {
    AssetCollectionsViewController *assetPickerViewController = [AssetCollectionsViewController new];
    assetPickerViewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:assetPickerViewController];
    [assetPickerViewController release];
    
#if !TARGET_OS_TV
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    navigationController.popoverPresentationController.sourceItem = sender;
#endif
    
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
}

- (void)_didTriggerDebugBarButtonItem:(UIBarButtonItem *)sender {
    CinematicViewModel *viewModel = self.viewModel;
    
    dispatch_async(viewModel.queue, ^{
        for (CNDecision *decision in [viewModel.isolated_snapshot.assetData.cnScript baseDecisionsInTimeRange:viewModel.isolated_snapshot.assetData.cnScript.timeRange]) {
            NSLog(@"%lld", decision.detectionID);
        }
        
        NSLog(@"------");
        
        for (CNDecision *decision in [viewModel.isolated_snapshot.assetData.cnScript decisionsInTimeRange:viewModel.isolated_snapshot.assetData.cnScript.timeRange]) {
            NSLog(@"%lld", decision.detectionID);
        }
    });
}

- (void)assetCollectionsViewController:(AssetCollectionsViewController *)assetCollectionsViewController didSelectAssets:(NSSet<PHAsset *> *)selectedAssets {
    [assetCollectionsViewController dismissViewControllerAnimated:YES completion:^{
        if (PHAsset *asset = selectedAssets.allObjects.firstObject) {
            [self _loadWithPHAsset:asset];
        }
    }];
}

- (void)_loadWithPHAsset:(PHAsset *)asset {
    if (NSProgress *oldProgress = self.progress) {
        [self _dismissPresentedAlertControllerForProgress:oldProgress];
        [self _removeObserverForProgress:oldProgress];
        [oldProgress cancel];
    }
    
    CinematicViewModel *viewModel = self.viewModel;
    
    NSProgress *progress = [CinematicAssetData loadDataFromPHAsset:asset completionHandler:^(CinematicAssetData * _Nullable data, NSError * _Nullable error) {
        assert(error == nil);
        assert(data != nil);
        
        dispatch_async(viewModel.queue, ^{
            [viewModel isolated_loadWithData:data];
        });
    }];
    
    self.progress = progress;
    [self _addObserverForProgress:progress];
    [self _presentProgressAlertControllerWithProgress:progress];
}

- (void)_presentProgressAlertControllerWithProgress:(NSProgress *)progress {
#if TARGET_OS_TV
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
#else
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
#endif
    progressView.observedProgress = progress;
    UIViewController *viewController = [UIViewController new];
    viewController.view = progressView;
    [progressView release];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Progress" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [progress cancel];
    }];
    [alertController addAction:cancelAction];
    
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(alertController, sel_registerName("setContentViewController:"), viewController);
    [viewController release];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)_dismissPresentedAlertControllerForProgress:(NSProgress *)progress {
    UIViewController *presentedViewController = self.presentedViewController;
    if (![presentedViewController isKindOfClass:[UIAlertController class]]) return;
    UIAlertController *alertController = static_cast<UIAlertController *>(presentedViewController);
    UIViewController *contentViewController = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(alertController, sel_registerName("contentViewController"));
    if (contentViewController == nil) return;
    UIView *view = contentViewController.view;
    if (![view isKindOfClass:[UIProgressView class]]) return;
    UIProgressView *progressView = static_cast<UIProgressView *>(view);
    NSProgress *observedProgress = progressView.observedProgress;
    if (![observedProgress isEqual:progress]) return;
    [alertController dismissViewControllerAnimated:YES completion:nil];
}

@end

#endif
