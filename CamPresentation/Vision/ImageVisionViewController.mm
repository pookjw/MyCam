//
//  ImageVisionViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/21/24.
//

#import <CamPresentation/ImageVisionViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <objc/objc-sync.h>
#import <CamPresentation/ImageVisionViewModel.h>
#import <CamPresentation/UIDeferredMenuElement+ImageVision.h>
#import <CamPresentation/ImageVisionView.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <TargetConditionals.h>

@interface ImageVisionViewController ()
@property (retain, nonatomic, readonly) ImageVisionViewModel *_viewModel;
@property (retain, nonatomic, readonly) ImageVisionView *_imageVisionView;
@property (retain, nonatomic, readonly) ImageVisionLayer *_imageVisionLayer;
@property (retain, nonatomic, readonly) UIBarButtonItem *_requestsMenuBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *_activityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *_activityIndicatorBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *_doneBarButtonItem;
@property (retain, nonatomic, readonly) SVRunLoop *_drawingRunLoop;
@property (retain, nonatomic, nullable) NSProgress *_progress;
@end

@implementation ImageVisionViewController
@synthesize _requestsMenuBarButtonItem = __requestsMenuBarButtonItem;
@synthesize _doneBarButtonItem = __doneBarButtonItem;
@synthesize _activityIndicatorView = __activityIndicatorView;
@synthesize _activityIndicatorBarButtonItem = __activityIndicatorBarButtonItem;

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
    
    [__viewModel removeObserver:self forKeyPath:@"loading"];
    [__viewModel release];
    [__imageVisionView release];
    [__imageVisionLayer release];
    [__requestsMenuBarButtonItem release];
    [__doneBarButtonItem release];
    [__activityIndicatorView release];
    [__activityIndicatorBarButtonItem release];
    [__drawingRunLoop release];
    [__progress cancel];
    [__progress release];
    
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
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ImageVisionView *imageVisionView = self._imageVisionView;
    [self.view addSubview:imageVisionView];
    imageVisionView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [imageVisionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [imageVisionView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [imageVisionView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [imageVisionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.rightBarButtonItems = @[
        self._requestsMenuBarButtonItem,
        self._activityIndicatorBarButtonItem,
        self._doneBarButtonItem
    ];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        __kindof UIControl *requestsMenuBarButton = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self._requestsMenuBarButtonItem, sel_registerName("view"));
//        
//        for (id<UIInteraction> interaction in requestsMenuBarButton.interactions) {
//            if ([interaction isKindOfClass:objc_lookUpClass("_UIClickPresentationInteraction")]) {
//                UIContextMenuInteraction *contextMenuInteraction = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(interaction, sel_registerName("delegate"));
//                reinterpret_cast<void (*)(id, SEL, CGPoint)>(objc_msgSend)(contextMenuInteraction, sel_registerName("_presentMenuAtLocation:"), CGPointZero);
//                break;
//            }
//        }
//    });
}

- (void)updateWithImage:(UIImage *)image {
    ImageVisionLayer *imageVisionLayer = self._imageVisionLayer;
    
    [self._drawingRunLoop runBlock:^{
        imageVisionLayer.image = image;
    }];
    
    assert(objc_sync_enter(self) == OBJC_SYNC_SUCCESS);
    [self._progress cancel];
    self._progress = [self._viewModel updateImage:image completionHandler:^(NSError * _Nullable error) {
        assert(error == nil);
    }];
    assert(objc_sync_exit(self) == OBJC_SYNC_SUCCESS);
}

- (void)updateWithAsset:(PHAsset *)asset {
    ImageVisionLayer *imageVisionLayer = self._imageVisionLayer;
    SVRunLoop *drawingRunLoop = self._drawingRunLoop;
    
    assert(objc_sync_enter(self) == OBJC_SYNC_SUCCESS);
    [self._progress cancel];
    self._progress = [self._viewModel updateImageWithPHAsset:asset completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
        assert(error == nil);
        
        [drawingRunLoop runBlock:^{
            imageVisionLayer.image = image;
        }];
    }];
    assert(objc_sync_exit(self) == OBJC_SYNC_SUCCESS);
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
    imageVisionView.backgroundColor = UIColor.blackColor;
    __imageVisionView = imageVisionView;
    __imageVisionLayer = [imageVisionView.imageVisionLayer retain];
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

- (UIBarButtonItem *)_doneBarButtonItem {
    if (auto doneBarButtonItem = __doneBarButtonItem) return doneBarButtonItem;
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_didTriggerDoneBarButtonItem:)];
    
    __doneBarButtonItem = [doneBarButtonItem retain];
    return [doneBarButtonItem autorelease];
}

- (UIActivityIndicatorView *)_activityIndicatorView {
    if (auto activityIndicatorView = __activityIndicatorView) return activityIndicatorView;
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
#if !TARGET_OS_TV
    activityIndicatorView.backgroundColor = UIColor.systemBackgroundColor;
#endif
    
    __activityIndicatorView = [activityIndicatorView retain];
    return [activityIndicatorView autorelease];
}

- (UIBarButtonItem *)_activityIndicatorBarButtonItem {
    if (auto activityIndicatorBarButtonItem = __activityIndicatorBarButtonItem) return activityIndicatorBarButtonItem;
    
    UIBarButtonItem *activityIndicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self._activityIndicatorView];
    
    __activityIndicatorBarButtonItem = [activityIndicatorBarButtonItem retain];
    return [activityIndicatorBarButtonItem autorelease];
}

- (void)_didTriggerDoneBarButtonItem:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    
#if !TARGET_OS_TV
    activityIndicatorBarButtonItem.hidden = !isLoading;
#endif
    
    UIActivityIndicatorView *activityIndicatorView = self._activityIndicatorView;
    
    if (isLoading) {
        [activityIndicatorView startAnimating];
    } else {
        [activityIndicatorView stopAnimating];
    }
}

@end
