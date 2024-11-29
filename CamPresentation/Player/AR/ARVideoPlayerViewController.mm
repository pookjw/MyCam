//
//  ARVideoPlayerViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/18/24.
//

#import <CamPresentation/ARVideoPlayerViewController.h>
#import <CamPresentation/CamPresentation-Swift.h>
#import <CamPresentation/UIApplication+mrui_requestSceneWrapper.hpp>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>
#if !TARGET_OS_TV
#import <ARKit/ARKit.h>
#endif

@interface ARVideoPlayerViewController ()
@property (retain, nonatomic, nullable) AVPlayer *player;
@property (retain, nonatomic, nullable, readonly) AVSampleBufferVideoRenderer *videoRenderer;
#if TARGET_OS_VISION
@property (retain, nonatomic, readonly) UIButton *toggleImmersiveSceneButton;
@property (readonly, nullable) UIScene *immersiveSpaceScene;
#endif
@end

@implementation ARVideoPlayerViewController
#if TARGET_OS_VISION
@synthesize toggleImmersiveSceneButton = _toggleImmersiveSceneButton;
#endif

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _player = [player retain];
    }
    
    return self;
}

- (instancetype)initWithVideoRenderer:(AVSampleBufferVideoRenderer *)videoRenderer {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _videoRenderer = [videoRenderer retain];
    }
    
    return self;
}

- (void)dealloc {
    [_player release];
    [_videoRenderer release];
#if TARGET_OS_VISION
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_toggleImmersiveSceneButton release];
#endif
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if !TARGET_OS_TV
    self.view.backgroundColor = UIColor.systemBackgroundColor;
#endif
    
    [self attachPlayerView];
    
#if TARGET_OS_VISION
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(receivedSceneWillConnectNotificaiton:)
                                               name:UISceneWillConnectNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(receivedSceneDidDisconnectNotificaiton:)
                                               name:UISceneDidDisconnectNotification
                                             object:nil];
    
    [self updateToggleImmersiveSceneButton];
#endif
}

- (void)didTriggerDoneBarButtonItem:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#if TARGET_OS_VISION
- (UIButton *)toggleImmersiveSceneButton {
    if (auto toggleImmersiveSceneButton = _toggleImmersiveSceneButton) return [[toggleImmersiveSceneButton retain] autorelease];
    
    UIButton *toggleImmersiveSceneButton = [UIButton new];
    [toggleImmersiveSceneButton addTarget:self action:@selector(didTriggerToggleImmersiveSceneButton:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    _toggleImmersiveSceneButton = [toggleImmersiveSceneButton retain];
    return [toggleImmersiveSceneButton autorelease];
}

- (void)didTriggerToggleImmersiveSceneButton:(UIButton *)sender {
    
}

- (UIScene *)immersiveSpaceScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.session.role == UISceneSessionRoleImmersiveSpaceApplication) {
            return scene;
        }
    }
    
    return nil;
}

- (void)receivedSceneWillConnectNotificaiton:(NSNotification *)notification {
    [self updateToggleImmersiveSceneButton];
}

- (void)receivedSceneDidDisconnectNotificaiton:(NSNotification *)notification {
    [self updateToggleImmersiveSceneButton];
}

- (void)updateToggleImmersiveSceneButton {
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    
    if (self.immersiveSpaceScene == nil) {
        configuration.image = [UIImage systemImageNamed:@"visionpro"];
    } else {
        configuration.image = [UIImage systemImageNamed:@"visionpro.fill"];
    }
    
    self.toggleImmersiveSceneButton.configuration = configuration;
}
#endif

- (void)attachPlayerView {
#if TARGET_OS_IOS
    UIView *view = self.view;
    
    __kindof UIViewController *arVideoPlayerViewController = CamPresentation::newARVideoPlayerHostingController(self.player, ^ (ARSession *arSession) {
        ARCoachingOverlayView *overlayView = [[ARCoachingOverlayView alloc] initWithFrame:view.bounds];
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [view addSubview:overlayView];
        
        overlayView.session = arSession;
        overlayView.goal = ARCoachingGoalAnyPlane;
        [overlayView release];
    });
    
    [self addChildViewController:arVideoPlayerViewController];
    arVideoPlayerViewController.view.frame = self.view.bounds;
    arVideoPlayerViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:arVideoPlayerViewController.view];
    [arVideoPlayerViewController didMoveToParentViewController:self];
    
    [arVideoPlayerViewController release];
#elif TARGET_OS_VISION
    UIButton *toggleImmersiveSceneButton = self.toggleImmersiveSceneButton;
    toggleImmersiveSceneButton.frame = self.view.bounds;
    toggleImmersiveSceneButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:toggleImmersiveSceneButton];
#endif
}

@end
