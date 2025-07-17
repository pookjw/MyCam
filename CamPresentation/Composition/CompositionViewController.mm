//
//  CompositionViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/16/25.
//

#import <CamPresentation/CompositionViewController.h>
#import <CamPresentation/AssetCollectionsViewController.h>
#import <CamPresentation/CompositionService.h>

@interface CompositionViewController () <AssetCollectionsViewControllerDelegate>
@property (retain, nonatomic, readonly, getter=_assetCollectionsBarButtonItem) UIBarButtonItem *assetCollectionsBarButtonItem;
@property (retain, nonatomic, readonly, getter=_compositionService) CompositionService *compositionService;
@end

@implementation CompositionViewController
@synthesize assetCollectionsBarButtonItem = _assetCollectionsBarButtonItem;
@synthesize compositionService = _compositionService;

- (void)dealloc {
    [_assetCollectionsBarButtonItem release];
    [_compositionService release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.rightBarButtonItems = @[
        self.assetCollectionsBarButtonItem
    ];
    
    dispatch_async(self.compositionService.queue, ^{
        [self.compositionService queue_loadLastComposition];
    });
}

- (UIBarButtonItem *)_assetCollectionsBarButtonItem {
    if (auto assetCollectionsBarButtonItem = _assetCollectionsBarButtonItem) return assetCollectionsBarButtonItem;
    
    UIBarButtonItem *assetCollectionsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Picker" image:[UIImage systemImageNamed:@"photo.badge.magnifyingglass.fill"] target:self action:@selector(_assetCollectionsBarButtonItemDidTrigger:) menu:nil];
    
    _assetCollectionsBarButtonItem = assetCollectionsBarButtonItem;
    return assetCollectionsBarButtonItem;
}

- (CompositionService *)_compositionService {
    if (auto compositionService = _compositionService) return compositionService;
    
    CompositionService *compositionService = [CompositionService new];
    
    _compositionService = compositionService;
    return compositionService;
}

- (void)_assetCollectionsBarButtonItemDidTrigger:(UIBarButtonItem *)sender {
    AssetCollectionsViewController *viewController = [AssetCollectionsViewController new];
    viewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [viewController release];
    
#if !TARGET_OS_TV
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    navigationController.popoverPresentationController.sourceItem = sender;
#endif
    
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
}

- (void)assetCollectionsViewController:(AssetCollectionsViewController *)assetCollectionsViewController didSelectAssets:(NSArray<PHAsset *> *)selectedAssets {
    [assetCollectionsViewController dismissViewControllerAnimated:YES completion:nil];
    
    if (selectedAssets.count == 0) return;
    
    dispatch_async(self.compositionService.queue, ^{
        [self.compositionService queue_addVideoSegmentsFromPHAssets:selectedAssets];
    });
}

@end
