//
//  VideoPlayerVisionViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/4/25.
//

#import <CamPresentation/VideoPlayerVisionViewController.h>
#import <CamPresentation/ImageVisionViewModel.h>
#import <CamPresentation/UIDeferredMenuElement+ImageVision.h>
#import <CamPresentation/ImageVisionView.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <CamPresentation/SampleBufferDisplayLayerView.h>
#import <CamPresentation/PlayerControlViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface VideoPlayerVisionViewController ()
@property (retain, nonatomic, readonly) ImageVisionViewModel *_viewModel;
@property (retain, nonatomic, readonly) SampleBufferDisplayLayerView *_sampleBufferDisplayLayerView;
@property (retain, nonatomic, readonly) AVSampleBufferDisplayLayer *_sampleBufferDisplayLayer;
@property (retain, nonatomic, readonly) ImageVisionView *_imageVisionView;
@property (retain, nonatomic, readonly) ImageVisionLayer *_imageVisionLayer;
@property (retain, nonatomic, readonly) UIBarButtonItem *_requestsMenuBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *_activityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *_activityIndicatorBarButtonItem;
@property (retain, nonatomic, readonly) PlayerControlViewController *_playerControlViewController;
@property (retain, nonatomic, readonly) SVRunLoop *_drawingRunLoop;
@property (retain, nonatomic, nullable) AVPlayerItemVideoOutput *_playerItemVideoOutput;
@end

@implementation VideoPlayerVisionViewController
@synthesize player = _player;
@synthesize _requestsMenuBarButtonItem = __requestsMenuBarButtonItem;
@synthesize _activityIndicatorView = __activityIndicatorView;
@synthesize _activityIndicatorBarButtonItem = __activityIndicatorBarButtonItem;
@synthesize _playerControlViewController = __playerControlViewController;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self _commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self _commonInit];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    [_player release];
    [__viewModel removeObserver:self forKeyPath:@"loading"];
    [__viewModel release];
    [__sampleBufferDisplayLayerView release];
    [__sampleBufferDisplayLayer release];
    [__imageVisionView release];
    [__imageVisionLayer release];
    [__requestsMenuBarButtonItem release];
    [__activityIndicatorView release];
    [__activityIndicatorBarButtonItem release];
    [__drawingRunLoop release];
    [__playerItemVideoOutput release];
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[ImageVisionViewModel class]]) {
        if ([keyPath isEqualToString:@"loading"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _didChangeLoadingStatus];
            });
            return;
        }
    } else if ([object isKindOfClass:[AVPlayer class]]) {
        if ([keyPath isEqualToString:@"currentItem"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                abort();
            });
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *view = self.view;
    
    SampleBufferDisplayLayerView *sampleBufferDisplayLayerView = self._sampleBufferDisplayLayerView;
    sampleBufferDisplayLayerView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:sampleBufferDisplayLayerView];
    
    ImageVisionView *imageVisionView = self._imageVisionView;
    imageVisionView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:imageVisionView];
    
    PlayerControlViewController *playerControlViewController = self._playerControlViewController;
    [self addChildViewController:playerControlViewController];
    playerControlViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:playerControlViewController.view];
    
    [NSLayoutConstraint activateConstraints:@[
        [sampleBufferDisplayLayerView.topAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.topAnchor],
        [sampleBufferDisplayLayerView.leadingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.leadingAnchor],
        [sampleBufferDisplayLayerView.trailingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.trailingAnchor],
        [sampleBufferDisplayLayerView.bottomAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.bottomAnchor],
        
        [imageVisionView.topAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.topAnchor],
        [imageVisionView.leadingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.leadingAnchor],
        [imageVisionView.trailingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.trailingAnchor],
        [imageVisionView.bottomAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.bottomAnchor],
        
        [playerControlViewController.view.leadingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.leadingAnchor],
        [playerControlViewController.view.trailingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.trailingAnchor],
        [playerControlViewController.view.bottomAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    
    [playerControlViewController didMoveToParentViewController:self];
    
    //
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.rightBarButtonItems = @[
        self._requestsMenuBarButtonItem,
        self._activityIndicatorBarButtonItem
    ];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __kindof UIControl *requestsMenuBarButton = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self._requestsMenuBarButtonItem, sel_registerName("view"));
        
        for (id<UIInteraction> interaction in requestsMenuBarButton.interactions) {
            if ([interaction isKindOfClass:objc_lookUpClass("_UIClickPresentationInteraction")]) {
                UIContextMenuInteraction *contextMenuInteraction = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(interaction, sel_registerName("delegate"));
                reinterpret_cast<void (*)(id, SEL, CGPoint)>(objc_msgSend)(contextMenuInteraction, sel_registerName("_presentMenuAtLocation:"), CGPointZero);
                break;
            }
        }
    });
}

- (void)setPlayer:(AVPlayer *)player {
    abort();
}

- (void)_commonInit {
    ImageVisionViewModel *viewModel = [ImageVisionViewModel new];
    [viewModel addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didChangeObservationsNotification:) name:ImageVisionViewModelDidChangeObservationsNotificationName object:viewModel];
    __viewModel = viewModel;
    
    //
    
    SVRunLoop *drawingRunLoop = [[SVRunLoop alloc] initWithThreadName:@"Image Vision Drawing Thread"];
    __drawingRunLoop = drawingRunLoop;
    
    //
    
    ImageVisionView *imageVisionView = [[ImageVisionView alloc] initWithDrawingRunLoop:drawingRunLoop];
    imageVisionView.backgroundColor = UIColor.clearColor;
    __imageVisionView = imageVisionView;
    __imageVisionLayer = [imageVisionView.imageVisionLayer retain];
    
    //
    
    SampleBufferDisplayLayerView *sampleBufferDisplayLayerView = [SampleBufferDisplayLayerView new];
    sampleBufferDisplayLayerView.backgroundColor = UIColor.blackColor;
    __sampleBufferDisplayLayerView = sampleBufferDisplayLayerView;
    __sampleBufferDisplayLayer = [sampleBufferDisplayLayerView.sampleBufferDisplayLayer retain];
}

- (UIBarButtonItem *)_requestsMenuBarButtonItem {
    if (auto requestsMenuBarButtonItem = __requestsMenuBarButtonItem) return requestsMenuBarButtonItem;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_imageVisionElementWithViewModel:self._viewModel imageVisionLayer:self._imageVisionLayer drawingRunLoop:self._drawingRunLoop]
    ]];
    
    UIBarButtonItem *requestsMenuBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"filemenu.and.selection"] menu:menu];
    
    __requestsMenuBarButtonItem = [requestsMenuBarButtonItem retain];
    return [requestsMenuBarButtonItem autorelease];
}

- (UIActivityIndicatorView *)_activityIndicatorView {
    if (auto activityIndicatorView = __activityIndicatorView) return activityIndicatorView;
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    activityIndicatorView.backgroundColor = UIColor.systemBackgroundColor;
    
    __activityIndicatorView = [activityIndicatorView retain];
    return [activityIndicatorView autorelease];
}

- (UIBarButtonItem *)_activityIndicatorBarButtonItem {
    if (auto activityIndicatorBarButtonItem = __activityIndicatorBarButtonItem) return activityIndicatorBarButtonItem;
    
    UIBarButtonItem *activityIndicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self._activityIndicatorView];
    
    __activityIndicatorBarButtonItem = [activityIndicatorBarButtonItem retain];
    return [activityIndicatorBarButtonItem autorelease];
}

- (void)_didChangeObservationsNotification:(NSNotification *)notification {
    ImageVisionLayer *imageVisionLayer = self._imageVisionLayer;
    SVRunLoop *drawingRunLoop = self._drawingRunLoop;
    
    [self._viewModel getValuesWithCompletionHandler:^(NSArray<__kindof VNRequest *> * _Nonnull requests, NSArray<__kindof VNObservation *> * _Nonnull observations, UIImage * _Nullable image) {
        [drawingRunLoop runBlock:^{
            imageVisionLayer.observations = observations;
        }];
    }];
}

- (void)_didChangeLoadingStatus {
    UIBarButtonItem *activityIndicatorBarButtonItem = self._activityIndicatorBarButtonItem;
    BOOL isLoading = self._viewModel.isLoading;
    
    activityIndicatorBarButtonItem.hidden = !isLoading;
    
    UIActivityIndicatorView *activityIndicatorView = self._activityIndicatorView;
    
    if (isLoading) {
        [activityIndicatorView startAnimating];
    } else {
        [activityIndicatorView stopAnimating];
    }
}

@end
