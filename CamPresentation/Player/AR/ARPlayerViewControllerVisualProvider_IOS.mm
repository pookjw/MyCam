//
//  ARPlayerViewControllerVisualProvider_IOS.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/10/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import <CamPresentation/ARPlayerViewControllerVisualProvider_IOS.h>
#import <CamPresentation/CamPresentation-Swift.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <ARKit/ARKit.h>

@interface ARPlayerViewControllerVisualProvider_IOS () {
    AVPlayer *_player;
    AVSampleBufferVideoRenderer *_videoRenderer;
}
@property (retain, nonatomic, nullable) __kindof UIViewController *_realityPlayerHostingController;
@end

@implementation ARPlayerViewControllerVisualProvider_IOS
@synthesize player = _player;
@synthesize videoRenderer = _videoRenderer;

- (void)dealloc {
    [_player release];
    [_videoRenderer release];
    [__realityPlayerHostingController release];
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
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    assert(self._realityPlayerHostingController == nil);
    
    ARPlayerViewController *playerViewController = self.playerViewController;
    UIView *view = playerViewController.view;
    
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
}

@end

#endif
