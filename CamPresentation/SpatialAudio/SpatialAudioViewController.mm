//
//  SpatialAudioViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/13/25.
//

#import <CamPresentation/SpatialAudioViewController.h>
#import <CamPresentation/AssetCollectionsViewController.h>
#import <CamPresentation/SpatialAudioViewModel.h>
#import <CamPresentation/NSStringFromCNSpatialAudioRenderingStyle.h>
#import <AVKit/AVKit.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <vector>
#include <ranges>
#import <CamPresentation/TVSlider.h>

@interface SpatialAudioViewController () <AssetCollectionsViewControllerDelegate>
@property (retain, nonatomic, readonly, getter=_playerViewController) AVPlayerViewController *playerViewController;
@property (retain, nonatomic, readonly, getter=_menuBarButtonItem) UIBarButtonItem *menuBarButtonItem;
@property (retain, nonatomic, readonly, getter=_assetCollectionsBarButtonItem) UIBarButtonItem *assetCollectionsBarButtonItem;
@property (retain, nonatomic, readonly, getter=_viewModel) SpatialAudioViewModel *viewModel;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly, getter=_spatialAudioMixEffectIntensitySlider) TVSlider *spatialAudioMixEffectIntensitySlider;
#else
@property (retain, nonatomic, readonly, getter=_spatialAudioMixEffectIntensitySlider) UISlider *spatialAudioMixEffectIntensitySlider;
#endif
@end

@implementation SpatialAudioViewController
@synthesize playerViewController = _playerViewController;
@synthesize menuBarButtonItem = _menuBarButtonItem;
@synthesize assetCollectionsBarButtonItem = _assetCollectionsBarButtonItem;
@synthesize viewModel = _viewModel;
@synthesize spatialAudioMixEffectIntensitySlider = _spatialAudioMixEffectIntensitySlider;

- (void)dealloc {
    [_playerViewController release];
    [_menuBarButtonItem release];
    [_assetCollectionsBarButtonItem release];
    [_viewModel release];
    [_spatialAudioMixEffectIntensitySlider release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if !TARGET_OS_TV
    self.view.backgroundColor = UIColor.systemBackgroundColor;
#endif
    self.navigationItem.rightBarButtonItems = @[self.menuBarButtonItem, self.assetCollectionsBarButtonItem];
    
    [self addChildViewController:self.playerViewController];
    self.playerViewController.view.frame = self.view.bounds;
    self.playerViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.playerViewController.view];
    [self.playerViewController didMoveToParentViewController:self];
    
//    PHAsset *phAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[@"104532A1-68C3-4E45-98C9-1F587079BE2F/L0/001"] options:nil].firstObject;
//    assert(phAsset != nil);
//    [self.viewModel updateWithPHAsset:phAsset completionHandler:^(NSError * _Nullable error) {
//        assert(error == nil);
//    }];
}

- (AVPlayerViewController *)_playerViewController {
    if (auto playerViewController = _playerViewController) return playerViewController;
    
    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    playerViewController.player = self.viewModel.player;
    
    _playerViewController = playerViewController;
    return playerViewController;
}

- (UIBarButtonItem *)_menuBarButtonItem {
    if (auto menuBarButtonItem = _menuBarButtonItem) return menuBarButtonItem;
    
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" image:[UIImage systemImageNamed:@"filemenu.and.selection"] target:nil action:nil menu:[self _makeMenu]];
    
    _menuBarButtonItem = menuBarButtonItem;
    return menuBarButtonItem;
}

- (UIMenu * _Nullable)_makeMenu {
    SpatialAudioViewModel *viewModel = self.viewModel;
#if TARGET_OS_TV
    TVSlider * _Nullable spatialAudioMixEffectIntensitySlider = self.spatialAudioMixEffectIntensitySlider;
#else
    UISlider * _Nullable spatialAudioMixEffectIntensitySlider = self.spatialAudioMixEffectIntensitySlider;
#endif
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
        
#if TARGET_OS_VISION || TARGET_OS_SIMULATOR
        {
            NSUInteger count;
            const NSInteger *allStyles = allCNSpatialAudioRenderingStyles(&count);
            
            auto actionsVec = std::views::iota(allStyles, allStyles + count)
            | std::views::transform([](const NSInteger *ptr) { return *ptr; })
            | std::views::transform([viewModel](const NSInteger style) -> UIAction * {
                UIAction *action = [UIAction actionWithTitle:NSStringFromCNSpatialAudioRenderingStyle(style) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    viewModel.renderingStyle = style;
                }];
                
                action.state = (viewModel.renderingStyle == style) ? UIMenuElementStateOn : UIMenuElementStateOff;
                return action;
            })
            | std::ranges::to<std::vector<UIAction *>>();
            
            NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
            UIMenu *menu = [UIMenu menuWithTitle:@"Rendering Style" children:actions];
            [actions release];
            [children addObject:menu];
        }
#else
        {
            NSUInteger count;
            const CNSpatialAudioRenderingStyle *allStyles = allCNSpatialAudioRenderingStyles(&count);
            
            auto actionsVec = std::views::iota(allStyles, allStyles + count)
            | std::views::transform([](const CNSpatialAudioRenderingStyle *ptr) { return *ptr; })
            | std::views::transform([viewModel](const CNSpatialAudioRenderingStyle style) -> UIAction * {
                UIAction *action = [UIAction actionWithTitle:NSStringFromCNSpatialAudioRenderingStyle(style) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    viewModel.renderingStyle = style;
                }];
                
                action.state = (viewModel.renderingStyle == style) ? UIMenuElementStateOn : UIMenuElementStateOff;
                return action;
            })
            | std::ranges::to<std::vector<UIAction *>>();
            
            NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
            UIMenu *menu = [UIMenu menuWithTitle:@"Rendering Style" children:actions];
            [actions release];
            [children addObject:menu];
        }
#endif
        
        {
            __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
                assert(spatialAudioMixEffectIntensitySlider != nil);
                return spatialAudioMixEffectIntensitySlider;
            });
            
            UIMenu *menu = [UIMenu menuWithTitle:@"Effect Intensity" children:@[element]];
            [children addObject:menu];
        }
        
        completion(children);
        [children release];
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[element]];
    return menu;
}

- (UIBarButtonItem *)_assetCollectionsBarButtonItem {
    if (auto assetCollectionsBarButtonItem = _assetCollectionsBarButtonItem) return assetCollectionsBarButtonItem;
    
    UIBarButtonItem *assetCollectionsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Picker" image:[UIImage systemImageNamed:@"photo.badge.magnifyingglass.fill"] target:self action:@selector(_assetCollectionsBarButtonItemDidTrigger:) menu:nil];
    
    _assetCollectionsBarButtonItem = assetCollectionsBarButtonItem;
    return assetCollectionsBarButtonItem;
}

- (SpatialAudioViewModel *)_viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    
    SpatialAudioViewModel *viewModel = [SpatialAudioViewModel new];
    
    _viewModel = viewModel;
    return viewModel;
}

#if TARGET_OS_TV
- (TVSlider *)_spatialAudioMixEffectIntensitySlider
#else
- (UISlider *)_spatialAudioMixEffectIntensitySlider
#endif
{
    if (auto spatialAudioMixEffectIntensitySlider = _spatialAudioMixEffectIntensitySlider) return spatialAudioMixEffectIntensitySlider;
    
#if TARGET_OS_TV
    TVSlider *spatialAudioMixEffectIntensitySlider = [TVSlider new];
#else
    UISlider *spatialAudioMixEffectIntensitySlider = [UISlider new];
#endif
    spatialAudioMixEffectIntensitySlider.minimumValue = 0.1f;
    spatialAudioMixEffectIntensitySlider.maximumValue = 1.f;
    spatialAudioMixEffectIntensitySlider.value = self.viewModel.effectIntensity;
    spatialAudioMixEffectIntensitySlider.continuous = YES;
    
    SpatialAudioViewModel *viewModel = self.viewModel;
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_TV
        float value = static_cast<TVSlider *>(action.sender).value;
#else
        float value = static_cast<UISlider *>(action.sender).value;
#endif
        viewModel.effectIntensity = value;
    }];
    
#if TARGET_OS_TV
    [spatialAudioMixEffectIntensitySlider addAction:action];
#else
    [spatialAudioMixEffectIntensitySlider addAction:action forControlEvents:UIControlEventValueChanged];
#endif
    
    _spatialAudioMixEffectIntensitySlider = spatialAudioMixEffectIntensitySlider;
    return spatialAudioMixEffectIntensitySlider;
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
    
    PHAsset *asset = selectedAssets.allObjects.firstObject;
    assert(asset != nil);
    [self.viewModel updateWithPHAsset:asset completionHandler: ^(NSError * _Nullable error) {
        assert(error == nil);
    }];
}

@end
