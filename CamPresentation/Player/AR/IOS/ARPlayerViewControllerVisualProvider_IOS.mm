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
#import <Vision/Vision.h>
#import <CamPresentation/CamPresentation-Swift.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <ARKit/ARKit.h>
#include <ranges>
#include <vector>

@interface ARPlayerViewControllerVisualProvider_IOS () {
    AVPlayer *_player;
}
@property (retain, nonatomic, nullable) __kindof UIViewController *_realityPlayerHostingController;
@property (retain, nonatomic, readonly) PlayerControlViewController *_controlViewController;
@property (retain, nonatomic, readonly) UIBarButtonItem *_renderTypeMenuBarButtonItem;
@end

@implementation ARPlayerViewControllerVisualProvider_IOS
@synthesize player = _player;
@synthesize _controlViewController = __controlViewController;
@synthesize _renderTypeMenuBarButtonItem = __renderTypeMenuBarButtonItem;

- (void)dealloc {
    [_player release];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ARPlayerViewController *playerViewController = self.playerViewController;
    
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

@end

#endif
