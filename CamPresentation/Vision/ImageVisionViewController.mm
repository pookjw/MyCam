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

@interface ImageVisionViewController ()
@property (retain, nonatomic, nullable, readonly) PHAsset *_asset;
@property (retain, nonatomic, nullable) UIImage *_image;
@property (retain, nonatomic, readonly) ImageVisionViewModel *_viewModel;
@property (retain, nonatomic, readonly) UIImageView *_imageView;
@property (retain, nonatomic, readonly) UIBarButtonItem *_requestsMenuBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *_doneBarButtonItem;
// TODO progress
@end

@implementation ImageVisionViewController
@synthesize _imageView = __imageView;
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
    [__imageView release];
    [__requestsMenuBarButtonItem release];
    [__doneBarButtonItem release];
    
    [super dealloc];
}

- (void)loadView {
    self.view = self._imageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ImageVisionViewModel *viewModel = [ImageVisionViewModel new];
    
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.leftBarButtonItems = @[
        self._requestsMenuBarButtonItem
    ];
    navigationItem.rightBarButtonItems = @[
        self._doneBarButtonItem
    ];
}

- (UIImageView *)_imageView {
    if (auto imageView = __imageView) return imageView;
    
    UIImageView *imageView = [UIImageView new];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = UIColor.systemBackgroundColor;
    
    __imageView = [imageView retain];
    return [imageView autorelease];
}

- (UIBarButtonItem *)_requestsMenuBarButtonItem {
    if (auto requestsMenuBarButtonItem = __requestsMenuBarButtonItem) return requestsMenuBarButtonItem;
    
//    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:requestClasses.count];
    
    UIBarButtonItem *requestsMenuBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"filemenu.and.selection"] menu:nil];
    
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

@end
