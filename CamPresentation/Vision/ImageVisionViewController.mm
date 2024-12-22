//
//  ImageVisionViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/21/24.
//

#import <CamPresentation/ImageVisionViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/Constants.h>
#import <CamPresentation/ImageVisionViewModel.h>
#import <CamPresentation/UIDeferredMenuElement+ImageVision.h>
#import <CamPresentation/ImageVisionView.h>

@interface ImageVisionViewController ()
@property (retain, nonatomic, nullable, readonly) PHAsset *_asset;
@property (retain, nonatomic, nullable) UIImage *_image;
@property (retain, nonatomic, nullable) ImageVisionViewModel *_viewModel;
@property (retain, nonatomic, readonly) ImageVisionView *_imageVisionView;
@property (retain, nonatomic, readonly) UIBarButtonItem *_requestsMenuBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *_doneBarButtonItem;
@property (retain, nonatomic, nullable) NSProgress *_progress;
@end

@implementation ImageVisionViewController
@synthesize _imageVisionView = __imageVisionView;
@synthesize _requestsMenuBarButtonItem = __requestsMenuBarButtonItem;
@synthesize _doneBarButtonItem = __doneBarButtonItem;

- (instancetype)initWithImage:(UIImage *)image {
    if (self = [super initWithNibName:nil bundle:nil]) {
        __image = [image retain];
    }
    
    return self;
}

- (instancetype)initWithAsset:(PHAsset *)asset {
    if (self = [super initWithNibName:nil bundle:nil]) {
        __asset = [asset retain];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    [__image release];
    [__asset release];
    [__imageVisionView release];
    [__requestsMenuBarButtonItem release];
    [__doneBarButtonItem release];
    
    if (NSProgress *progress = __progress) {
        [progress cancel];
        [progress release];
    }
    
    [super dealloc];
}

- (void)loadView {
    self.view = self._imageVisionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ImageVisionViewModel *viewModel = [ImageVisionViewModel new];
    
    if (UIImage *image = self._image) {
        self._progress = [viewModel updateImage:image completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
        
        self._imageVisionView.imageVisionLayer.image = image;
    } else if (PHAsset *asset = self._asset) {
        ImageVisionView *imageVisionView = self._imageVisionView;
        
        self._progress = [viewModel updateImageWithPHAsset:asset completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
            assert(error == nil);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                imageVisionView.imageVisionLayer.image = image;
            });
        }];
    }
    
    self._viewModel = viewModel;
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didChangeObservationsNotification:) name:ImageVisionViewModelDidChangeObservationsNotificationName object:viewModel];
    
    [viewModel release];
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.leftBarButtonItems = @[
        self._requestsMenuBarButtonItem
    ];
    navigationItem.rightBarButtonItems = @[
        self._doneBarButtonItem
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

- (ImageVisionView *)_imageVisionView {
    if (auto imageVisionView = __imageVisionView) return imageVisionView;
    
    ImageVisionView *imageVisionView = [ImageVisionView new];
    imageVisionView.backgroundColor = UIColor.systemBackgroundColor;
    
    __imageVisionView = [imageVisionView retain];
    return [imageVisionView autorelease];
}

- (UIBarButtonItem *)_requestsMenuBarButtonItem {
    if (auto requestsMenuBarButtonItem = __requestsMenuBarButtonItem) return requestsMenuBarButtonItem;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_imageVisionElementWithViewModel:self._viewModel]
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

- (void)_setReadyForProcess:(BOOL)ready {
    self._requestsMenuBarButtonItem.enabled = ready;
}

- (void)_didTriggerDoneBarButtonItem:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_didChangeObservationsNotification:(NSNotification *)notification {
    [self._viewModel observationsWithHandler:^(NSArray<__kindof VNObservation *> * _Nonnull observations) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self._imageVisionView.imageVisionLayer.observations = observations;
        });
    }];
}

@end
