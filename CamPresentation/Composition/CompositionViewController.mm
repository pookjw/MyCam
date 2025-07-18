//
//  CompositionViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/16/25.
//

#import <CamPresentation/CompositionViewController.h>
#import <CamPresentation/AssetCollectionsViewController.h>
#import <CamPresentation/CompositionService.h>
#import <CamPresentation/CompositionPlayerViewController.h>
#import <CamPresentation/CompositionTracksViewController.h>
#import <CamPresentation/UIDeferredMenuElement+Composition.h>
#include <objc/message.h>
#include <objc/runtime.h>

@interface CompositionViewController () <AssetCollectionsViewControllerDelegate>
@property (retain, nonatomic, readonly, getter=_menuBarButtonItem) UIBarButtonItem *menuBarButtonItem;
@property (retain, nonatomic, readonly, getter=_assetCollectionsBarButtonItem) UIBarButtonItem *assetCollectionsBarButtonItem;
@property (retain, nonatomic, readonly, getter=_stackView) UIStackView *stackView;
@property (retain, nonatomic, readonly, getter=_playerViewController) CompositionPlayerViewController *playerViewController;
@property (retain, nonatomic, readonly, getter=_tracksViewController) CompositionTracksViewController *tracksViewController;
@property (retain, nonatomic, readonly, getter=_compositionService) CompositionService *compositionService;
@property (retain, nonatomic, nullable, getter=_progress, setter=_setProgress:) NSProgress *progress;
@end

@implementation CompositionViewController
@synthesize menuBarButtonItem = _menuBarButtonItem;
@synthesize assetCollectionsBarButtonItem = _assetCollectionsBarButtonItem;
@synthesize stackView = _stackView;
@synthesize playerViewController = _playerViewController;
@synthesize tracksViewController = _tracksViewController;
@synthesize compositionService = _compositionService;

- (void)dealloc {
    [_menuBarButtonItem release];
    [_assetCollectionsBarButtonItem release];
    [_stackView release];
    [_playerViewController release];
    [_tracksViewController release];
    [_compositionService release];
    [_progress cancel];
    [_progress removeObserver:self forKeyPath:@"finished"];
    [_progress release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[NSProgress class]] && [keyPath isEqualToString:@"finished"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([object isEqual:self.progress] && (self.progress.finished || self.progress.cancelled)) {
                [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
            }
        });
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.rightBarButtonItems = @[
        self.menuBarButtonItem,
        self.assetCollectionsBarButtonItem
    ];
    
    self.stackView.frame = self.view.bounds;
    self.stackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.stackView];
    
    [self addChildViewController:self.playerViewController];
    [self.stackView addArrangedSubview:self.playerViewController.view];
    [self.playerViewController didMoveToParentViewController:self];
    
    [self addChildViewController:self.tracksViewController];
    [self.stackView addArrangedSubview:self.tracksViewController.view];
    [self.tracksViewController didMoveToParentViewController:self];
}

- (UIBarButtonItem *)_menuBarButtonItem {
    if (auto menuBarButtonItem = _menuBarButtonItem) return menuBarButtonItem;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_compositionElementWithCompositionService:self.compositionService didChangeHandler:nil]
    ]];
    
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" image:[UIImage systemImageNamed:@"filemenu.and.selection"] target:nil action:nil menu:menu];
    
    _menuBarButtonItem = menuBarButtonItem;
    return menuBarButtonItem;
}

- (UIBarButtonItem *)_assetCollectionsBarButtonItem {
    if (auto assetCollectionsBarButtonItem = _assetCollectionsBarButtonItem) return assetCollectionsBarButtonItem;
    
    UIBarButtonItem *assetCollectionsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Picker" image:[UIImage systemImageNamed:@"photo.badge.magnifyingglass.fill"] target:self action:@selector(_assetCollectionsBarButtonItemDidTrigger:) menu:nil];
    
    _assetCollectionsBarButtonItem = assetCollectionsBarButtonItem;
    return assetCollectionsBarButtonItem;
}

- (CompositionPlayerViewController *)_playerViewController {
    if (auto playerViewController = _playerViewController) return playerViewController;
    
    CompositionPlayerViewController *playerViewController = [[CompositionPlayerViewController alloc] initWithCompositionService:self.compositionService];
    
    _playerViewController = playerViewController;
    return playerViewController;
}

- (CompositionTracksViewController *)_tracksViewController {
    if (auto tracksViewController = _tracksViewController) return tracksViewController;
    
    CompositionTracksViewController *tracksViewController = [[CompositionTracksViewController alloc] initWithCompositionService:self.compositionService];
    
    _tracksViewController = tracksViewController;
    return tracksViewController;
}

- (UIStackView *)_stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = stackView;
    return stackView;
}

- (CompositionService *)_compositionService {
    if (auto compositionService = _compositionService) return compositionService;
    
    CompositionService *compositionService = [CompositionService new];
    
    _compositionService = compositionService;
    return compositionService;
}

- (void)_setProgress:(NSProgress *)progress {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (NSProgress *oldProgress = _progress) {
        [oldProgress cancel];
        [oldProgress removeObserver:self forKeyPath:@"finished"];
        [oldProgress release];
    }
    
    _progress = [progress retain];
    [progress addObserver:self forKeyPath:@"finished" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

- (void)_assetCollectionsBarButtonItemDidTrigger:(UIBarButtonItem *)sender {
    AssetCollectionsViewController *viewController = [AssetCollectionsViewController new];
    viewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [viewController release];
    
#if !TARGET_OS_TV
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    navigationController.popoverPresentationController.sourceItem = sender;
    navigationController.preferredContentSize = CGSizeMake(600., 600.);
#endif
    
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
}

- (void)assetCollectionsViewController:(AssetCollectionsViewController *)assetCollectionsViewController didSelectAssets:(NSArray<PHAsset *> *)selectedAssets {
    [assetCollectionsViewController dismissViewControllerAnimated:NO completion:nil];
    
    if (selectedAssets.count == 0) return;
    
    NSProgress *progress = [self.compositionService nonisolated_addVideoSegmentsFromPHAssets:selectedAssets];
    [self _observeProgress:progress];
}

- (void)_observeProgress:(NSProgress *)progress {
    self.progress = progress;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Loading" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIViewController *contentViewController = [[UIViewController alloc] init];
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressView.observedProgress = progress;
    contentViewController.view = progressView;
    [progressView release];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(alertController, sel_registerName("setContentViewController:"), contentViewController);
    [contentViewController release];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [progress cancel];
    }];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
