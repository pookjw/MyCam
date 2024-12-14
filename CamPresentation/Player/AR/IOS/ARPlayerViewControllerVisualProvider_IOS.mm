//
//  ARPlayerViewControllerVisualProvider_IOS.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/10/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import <CamPresentation/ARPlayerViewControllerVisualProvider_IOS.h>
#import <CamPresentation/PlayerControlViewController.h>
#import <CamPresentation/CamPresentation-Swift.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <ARKit/ARKit.h>
#include <ranges>
#include <vector>

@interface ARPlayerViewControllerVisualProvider_IOS () {
    AVPlayer *_player;
    AVSampleBufferVideoRenderer *_videoRenderer;
}
@property (retain, nonatomic, nullable) __kindof UIViewController *_realityPlayerHostingController;
@property (retain, nonatomic, readonly) PlayerControlViewController *_controlViewController;
@property (retain, nonatomic, readonly) UIBarButtonItem *_renderTypeMenuBarButtonItem;
@end

@implementation ARPlayerViewControllerVisualProvider_IOS
@synthesize player = _player;
@synthesize videoRenderer = _videoRenderer;
@synthesize _controlViewController = __controlViewController;
@synthesize _renderTypeMenuBarButtonItem = __renderTypeMenuBarButtonItem;

- (void)dealloc {
    [_player release];
    [_videoRenderer release];
    [__realityPlayerHostingController release];
    [__controlViewController release];
    [__renderTypeMenuBarButtonItem release];
    [super dealloc];
}

- (AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    return _player;
}

- (void)setPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    [_player release];
    _player = [player retain];
    
    if (auto realityPlayerHostingController = self._realityPlayerHostingController) {
        CamPresentation::setAVPlayer_IOS(player, realityPlayerHostingController);
    }
}

- (AVSampleBufferVideoRenderer *)videoRenderer {
    dispatch_assert_queue(dispatch_get_main_queue());
    return _videoRenderer;
}

- (void)setVideoRenderer:(AVSampleBufferVideoRenderer *)videoRenderer {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    [_videoRenderer release];
    _videoRenderer = [videoRenderer retain];
    
    if (auto realityPlayerHostingController = self._realityPlayerHostingController) {
        CamPresentation::setVideoRenderer_IOS(videoRenderer, realityPlayerHostingController);
        
        if (videoRenderer == nil) {
            CamPresentation::setAVPlayer_IOS(self.player, realityPlayerHostingController);
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ARPlayerViewController *playerViewController = self.playerViewController;
    UINavigationItem *navigationItem = playerViewController.navigationItem;
    
    UIBarButtonItem *renderTypeMenuBarButtonItem = self._renderTypeMenuBarButtonItem;
    navigationItem.rightBarButtonItem = renderTypeMenuBarButtonItem;
    
    assert(self._realityPlayerHostingController == nil);
    
    __block UIView *view = playerViewController.view;
    
    view.backgroundColor = UIColor.systemBackgroundColor;
    
    auto arSessionHandler = ^ (ARSession *arSession) {
        ARCoachingOverlayView *overlayView = [[ARCoachingOverlayView alloc] initWithFrame:view.bounds];
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [view addSubview:overlayView];
        
        overlayView.session = arSession;
        overlayView.goal = ARCoachingGoalAnyPlane;
        [overlayView release];
    };
    
    __kindof UIViewController *realityPlayerHostingController;
    if (AVPlayer *player = self.player) {
        realityPlayerHostingController = CamPresentation::newRealityPlayerHostingControllerFromPlayer_IOS(player, arSessionHandler);
    } else if (AVSampleBufferVideoRenderer *videoRenderer = self.videoRenderer) {
        realityPlayerHostingController = CamPresentation::newRealityPlayerHostingControllerFromVideoRenderer_IOS(videoRenderer, arSessionHandler);
    } else {
        realityPlayerHostingController = CamPresentation::newRealityPlayerHostingController_IOS(arSessionHandler);
    }
    
    self._realityPlayerHostingController = realityPlayerHostingController;
    
    [playerViewController addChildViewController:realityPlayerHostingController];
    realityPlayerHostingController.view.frame = view.bounds;
    realityPlayerHostingController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:realityPlayerHostingController.view];
    [realityPlayerHostingController didMoveToParentViewController:playerViewController];
    
    [realityPlayerHostingController release];
    
    //
    
    PlayerControlViewController *controlViewController = self._controlViewController;
    PlayerControlView *controlView = controlViewController.controlView;
    
    [playerViewController addChildViewController:controlViewController];
    controlView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:controlView];
    [NSLayoutConstraint activateConstraints:@[
        [controlView.leadingAnchor constraintEqualToAnchor:view.layoutMarginsGuide.leadingAnchor],
        [controlView.trailingAnchor constraintEqualToAnchor:view.layoutMarginsGuide.trailingAnchor],
        [controlView.bottomAnchor constraintEqualToAnchor:view.layoutMarginsGuide.bottomAnchor]
    ]];
}

- (PlayerControlViewController *)_controlViewController {
    if (auto controlViewController = __controlViewController) return controlViewController;
    
    PlayerControlViewController *controlViewController = [PlayerControlViewController new];
    controlViewController.controlView.player = self.player;
    
    __controlViewController = [controlViewController retain];
    return [controlViewController autorelease];
}

- (UIBarButtonItem *)_renderTypeMenuBarButtonItem {
    if (auto renderTypeMenuBarButtonItem = __renderTypeMenuBarButtonItem) return renderTypeMenuBarButtonItem;
    
    __block auto unretained = self;
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        auto _self = unretained;
        id<ARPlayerViewControllerVisualProviderDelegate> delegate = _self.delegate;
        
        if (delegate == nil) {
            completion(@[]);
            return;
        }
        
        ARPlayerRenderType selectedRenderType = [delegate rednerTypeWithPlayerViewControllerVisualProvider:_self];
        
        NSUInteger count;
        ARPlayerRenderType *allTypes = allARPlayerRenderTypes(&count);
        
        auto actionsVector = std::views::iota(allTypes, allTypes + count)
        | std::views::transform([_self, selectedRenderType](const ARPlayerRenderType *renderTypePtr) {
            const ARPlayerRenderType renderType = *renderTypePtr;
            __block auto unretained = _self;
            
            UIAction *action = [UIAction actionWithTitle:NSStringFromARPlayerRenderType(renderType) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [unretained.delegate playerViewControllerVisualProvider:unretained didSelectRenderType:renderType];
            }];
            
            action.state = (selectedRenderType == renderType) ? UIMenuElementStateOn : UIMenuElementStateOff;
            
            return action;
        })
        | std::ranges::to<std::vector<UIAction *>>();
        
        NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVector.data() count:actionsVector.size()];
        
        completion(actions);
        [actions release];
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[element]];
    
    UIBarButtonItem *renderTypeMenuBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Render Type" menu:menu];
    
    __renderTypeMenuBarButtonItem = [renderTypeMenuBarButtonItem retain];
    return [renderTypeMenuBarButtonItem autorelease];
}

@end

#endif
