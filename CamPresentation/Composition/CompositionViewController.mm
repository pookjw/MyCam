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
#if !TARGET_OS_TV
    viewController.modalPresentationStyle = UIModalPresentationPopover;
    viewController.popoverPresentationController.sourceItem = sender;
#endif
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [viewController release];
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
}

- (void)assetCollectionsViewController:(AssetCollectionsViewController *)assetCollectionsViewController didSelectAssets:(NSSet<PHAsset *> *)selectedAssets {
    [assetCollectionsViewController dismissViewControllerAnimated:YES completion:nil];
    
//    PHAsset *asset = selectedAssets.allObjects.firstObject;
//    assert(asset != nil);
//    [self.viewModel updateWithPHAsset:asset completionHandler: ^(NSError * _Nullable error) {
//        assert(error == nil);
//    }];
}

@end
