//
//  ARPlayerViewControllerVisualProvider_Vision.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/11/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/ARPlayerViewControllerVisualProvider_Vision.h>
#import <CamPresentation/UIApplication+mrui_requestSceneWrapper.hpp>
#import <CamPresentation/ARPlayerWindowScene.h>
#import <CamPresentation/Constants.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface ARPlayerViewControllerVisualProvider_Vision () {
    AVPlayer *_player;
    AVSampleBufferVideoRenderer *_videoRenderer;
}
@property (retain, nonatomic, readonly) UIButton *_toggleImmersiveSceneButton;
@property (readonly, nullable) ARPlayerWindowScene *_immersiveSpaceScene;
@end

@implementation ARPlayerViewControllerVisualProvider_Vision
@synthesize player = _player;
@synthesize videoRenderer = _videoRenderer;
@synthesize _toggleImmersiveSceneButton = __toggleImmersiveSceneButton;
@synthesize _immersiveSpaceScene = __immersiveSpaceScene;

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_player release];
    [_videoRenderer release];
    [__toggleImmersiveSceneButton release];
    [__immersiveSpaceScene release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *view = self.playerViewController.view;
    
    UIButton *toggleImmersiveSceneButton = self._toggleImmersiveSceneButton;
    [view addSubview:toggleImmersiveSceneButton];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(view, sel_registerName("_addBoundsMatchingConstraintsForView:"), toggleImmersiveSceneButton);
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_receivedSceneWillConnectNotificaiton:)
                                               name:UISceneWillConnectNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_receivedSceneDidDisconnectNotificaiton:)
                                               name:UISceneDidDisconnectNotification
                                             object:nil];
    
    [self _updateToggleImmersiveSceneButton];
}

- (AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    return _player;
}

- (void)setPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    [_player release];
    _player = [player retain];
    
    self._immersiveSpaceScene.player = player;
}

- (AVSampleBufferVideoRenderer *)videoRenderer {
    dispatch_assert_queue(dispatch_get_main_queue());
    return _videoRenderer;
}

- (void)setVideoRenderer:(AVSampleBufferVideoRenderer *)videoRenderer {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    [_videoRenderer release];
    _videoRenderer = [videoRenderer retain];
    
    self._immersiveSpaceScene.videoRenderer = videoRenderer;
}

- (UIButton *)_toggleImmersiveSceneButton {
    if (auto toggleImmersiveSceneButton = __toggleImmersiveSceneButton) return [[toggleImmersiveSceneButton retain] autorelease];
    
    UIButton *toggleImmersiveSceneButton = [UIButton new];
    [toggleImmersiveSceneButton addTarget:self action:@selector(_didTriggerToggleImmersiveSceneButton:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    __toggleImmersiveSceneButton = [toggleImmersiveSceneButton retain];
    return [toggleImmersiveSceneButton autorelease];
}

- (ARPlayerWindowScene *)_immersiveSpaceScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.session.role != UISceneSessionRoleImmersiveSpaceApplication) {
            continue;
        }
        
        if (![scene isKindOfClass:ARPlayerWindowScene.class]) {
            continue;
        }
        
        return static_cast<ARPlayerWindowScene *>(scene);
    }
    
    return nil;
}

- (void)_didTriggerToggleImmersiveSceneButton:(UIButton *)sender {
    if (UIScene *immersiveSpaceScene = self._immersiveSpaceScene) {
        [UIApplication.sharedApplication requestSceneSessionDestruction:immersiveSpaceScene.session options:nil errorHandler:^(NSError * _Nonnull error) {
            abort();
        }];
    } else {
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:CPSceneActivityType];
        
        userActivity.userInfo = @{
            CPSceneTypeKey: CPARPlayerScene
        };
        
        [UIApplication.sharedApplication mruiw_requestMixedImmersiveSceneWithUserActivity:userActivity completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
            
            ARPlayerWindowScene *scene = self._immersiveSpaceScene;
            assert(scene != nil);
            
            if (AVPlayer *player = self.player) {
                scene.player = player;
            } else if (AVSampleBufferVideoRenderer *videoRenderer = self.videoRenderer) {
                scene.videoRenderer = videoRenderer;
            }
        }];
        
        [userActivity release];
    }
}

- (void)_receivedSceneWillConnectNotificaiton:(NSNotification *)notification {
    [self _updateToggleImmersiveSceneButton];
}

- (void)_receivedSceneDidDisconnectNotificaiton:(NSNotification *)notification {
    [self _updateToggleImmersiveSceneButton];
}

- (void)_updateToggleImmersiveSceneButton {
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    
    if (self._immersiveSpaceScene == nil) {
        configuration.image = [UIImage systemImageNamed:@"visionpro"];
    } else {
        configuration.image = [UIImage systemImageNamed:@"visionpro.fill"];
    }
    
    self._toggleImmersiveSceneButton.configuration = configuration;
}

@end

#endif
