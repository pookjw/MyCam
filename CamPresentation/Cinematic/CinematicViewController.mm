//
//  CinematicViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicViewController.h>
#import <CamPresentation/AssetCollectionsViewController.h>
#import <CamPresentation/CinematicViewModel.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface CinematicViewController () <AssetCollectionsViewControllerDelegate>
@property (retain, nonatomic, readonly, getter=_assetPickerBarButtonItem) UIBarButtonItem *assetPickerBarButtonItem;
@property (retain, nonatomic, readonly, getter=_assetPickerViewController) AssetCollectionsViewController *assetPickerViewController;
@property (retain, nonatomic, readonly, getter=_viewModel) CinematicViewModel *viewModel;
@property (retain, nonatomic, getter=_progress, setter=_setProgress:) NSProgress *progress;
@end

@implementation CinematicViewController
@synthesize assetPickerBarButtonItem = _assetPickerBarButtonItem;
@synthesize assetPickerViewController = _assetPickerViewController;
@synthesize viewModel = _viewModel;
@synthesize progress = _progress;

- (void)dealloc {
    [_assetPickerBarButtonItem release];
    [_assetPickerViewController release];
    [_viewModel release];
    
    if (NSProgress *progress = self.progress) {
        [self _removeObserverForProgress:progress];
        [progress cancel];
        [progress release];
    }
    
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
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.style = UINavigationItemStyleEditor;
    navigationItem.trailingItemGroups = @[
        [UIBarButtonItemGroup fixedGroupWithRepresentativeItem:nil items:@[
            self.assetPickerBarButtonItem
        ]]
    ];
    
    {
        PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[@"80BF37FF-7827-4B49-B6DF-3A0CC9C5D5ED/L0/001"] options:nil];
        [self _loadWithPHAsset:assets[0]];
    }
}

- (UIBarButtonItem *)_assetPickerBarButtonItem {
    if (auto assetPickerBarButtonItem = _assetPickerBarButtonItem) return assetPickerBarButtonItem;
    
    UIBarButtonItem *assetPickerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"photo"] style:UIBarButtonItemStylePlain target:self action:@selector(_didTriggerAssetPickerBarButtonItem:)];
    
    _assetPickerBarButtonItem = assetPickerBarButtonItem;
    return assetPickerBarButtonItem;
}

- (AssetCollectionsViewController *)_assetPickerViewController {
    if (auto assetPickerViewController = _assetPickerViewController) return assetPickerViewController;
    
    AssetCollectionsViewController *assetPickerViewController = [AssetCollectionsViewController new];
    assetPickerViewController.delegate = self;
    
    _assetPickerViewController = assetPickerViewController;
    return assetPickerViewController;
}

- (CinematicViewModel *)_viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    
    CinematicViewModel *viewModel = [CinematicViewModel new];
    
    _viewModel = viewModel;
    return viewModel;
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
    AssetCollectionsViewController *assetPickerViewController = self.assetPickerViewController;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:assetPickerViewController];
    [assetPickerViewController release];
    
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    navigationController.popoverPresentationController.sourceItem = sender;
    
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
}

- (void)assetCollectionsViewController:(AssetCollectionsViewController *)assetCollectionsViewController didSelectAssets:(NSSet<PHAsset *> *)selectedAssets {
    if (PHAsset *asset = selectedAssets.allObjects.firstObject) {
        [self _loadWithPHAsset:asset];
    }
}

- (void)_loadWithPHAsset:(PHAsset *)asset {
    if (NSProgress *oldProgress = self.progress) {
        [self _dismissPresentedAlertControllerForProgress:oldProgress];
        [self _removeObserverForProgress:oldProgress];
        [oldProgress cancel];
    }
    
    NSProgress *progress = [CinematicViewModel loadCNAssetInfoFromPHAsset:asset completionHandler:^(CNAssetInfo * _Nullable cinematicAssetInfo, NSError * _Nullable error) {
        assert(error == nil);
        NSLog(@"%@", cinematicAssetInfo);
        NSLog(@"%@", cinematicAssetInfo.allCinematicTracks);
    }];
    
    self.progress = progress;
    [self _addObserverForProgress:progress];
    [self _presentProgressAlertControllerWithProgress:progress];
}

- (void)_presentProgressAlertControllerWithProgress:(NSProgress *)progress {
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
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
