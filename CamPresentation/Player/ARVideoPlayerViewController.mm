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
#import <ARKit/ARKit.h>

@interface ARVideoPlayerViewController ()
@property (retain, nonatomic, nullable, readonly) PHAsset *asset;
@property (retain, nonatomic, nullable) AVPlayer *player;
@property (retain, nonatomic, nullable, readonly) AVSampleBufferVideoRenderer *videoRenderer;
@property (retain, nonatomic, readonly) UIBarButtonItem *doneBarButtonItem;
@property (assign, nonatomic) PHImageRequestID imageRequestID;
#if TARGET_OS_VISION
@property (retain, nonatomic, readonly) UIButton *toggleImmersiveSceneButton;
@property (readonly, nullable) UIScene *immersiveSpaceScene;
#endif
@end

@implementation ARVideoPlayerViewController
@synthesize doneBarButtonItem = _doneBarButtonItem;
#if TARGET_OS_VISION
@synthesize toggleImmersiveSceneButton = _toggleImmersiveSceneButton;
#endif

- (instancetype)initWithAsset:(PHAsset *)asset {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _asset = [asset retain];
        _imageRequestID = PHInvalidImageRequestID;
    }
    
    return self;
}

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _player = [player retain];
        _imageRequestID = PHInvalidImageRequestID;
    }
    
    return self;
}

- (instancetype)initWithVideoRenderer:(AVSampleBufferVideoRenderer *)videoRenderer {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _videoRenderer = [videoRenderer retain];
        _imageRequestID = PHInvalidImageRequestID;
    }
    
    return self;
}

- (void)dealloc {
    if (_imageRequestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:_imageRequestID];
    }
    
    [_asset release];
    [_player release];
    [_videoRenderer release];
    [_doneBarButtonItem release];
#if TARGET_OS_VISION
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_toggleImmersiveSceneButton release];
#endif
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.rightBarButtonItem = self.doneBarButtonItem;
    
    if (PHAsset *asset = self.asset) {
        UIProgressView *progressView = [UIProgressView new];
        progressView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:progressView];
        [NSLayoutConstraint activateConstraints:@[
            [progressView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
            [progressView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
            [progressView.centerYAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.centerYAnchor]
        ]];
        
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), dispatch_get_main_queue());
        options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [progressView setProgress:progress animated:YES];
            });
        };
        [progressView release];
        
        __weak auto weakSelf = self;
        
        self.imageRequestID = [PHImageManager.defaultManager requestPlayerItemForVideo:asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            if (NSNumber *cancelledNumber = info[PHImageCancelledKey]) {
                if (cancelledNumber.boolValue) return;
            }
            
            auto retained = weakSelf;
            if (retained == nil) return;
            
            assert(playerItem != nil);
            
            AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            retained.player = player;
            [player release];
            
            [progressView removeFromSuperview];
            [retained attachPlayerView];
        }];
        
        [options release];
    } else {
        [self attachPlayerView];
    }
    
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

- (UIBarButtonItem *)doneBarButtonItem {
    if (auto doneBarButtonItem = _doneBarButtonItem) return [[doneBarButtonItem retain] autorelease];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didTriggerDoneBarButtonItem:)];
    
    _doneBarButtonItem = [doneBarButtonItem retain];
    return [doneBarButtonItem autorelease];
}

- (void)didTriggerDoneBarButtonItem:(UIBarButtonItem *)sender {
    if (self.imageRequestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:self.imageRequestID];
        self.imageRequestID = PHInvalidImageRequestID;
    }
    
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
    __weak auto wealSelf = self;
    
    __kindof UIViewController *arVideoPlayerViewController = CamPresentation::newARVideoPlayerHostingController(self.player, ^ (ARSession *arSession) {
        auto retained = wealSelf;
        if (retained == nil) return;
        
        ARCoachingOverlayView *overlayView = [[ARCoachingOverlayView alloc] initWithFrame:retained.view.bounds];
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [retained.view addSubview:overlayView];
        
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
