//
//  XRCamRootViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/XRCamRootViewController.h>
#import <CamPresentation/XRCaptureService.h>
#import <CamPresentation/XRCaptureVideoPreviewView.h>
#import <CamPresentation/XRCamMenuViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface XRCamRootViewController ()
@property (retain, nonatomic, readonly) XRCaptureService *captureService;
@property (retain, nonatomic, readonly) XRCaptureVideoPreviewView *previewView;
@property (retain, nonatomic, readonly) XRCamMenuViewController *menuViewController;
@property (retain, nonatomic, readonly) id menuOrnament;
@end

@implementation XRCamRootViewController
@synthesize captureService = _captureService;
@synthesize menuOrnament = _menuOrnament;
@synthesize menuViewController = _menuViewController;

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_captureService release];
    [_menuViewController release];
    [_menuOrnament release];
    [super dealloc];
}

- (void)loadView {
    XRCaptureVideoPreviewView *previewView = [XRCaptureVideoPreviewView new];
    self.view = previewView;
    [previewView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    id mrui_ornamentsItem = reinterpret_cast<id (*) (id, SEL)>(objc_msgSend) (self, NSSelectorFromString(@"mrui_ornamentsItem"));
    reinterpret_cast<void (*) (id, SEL, id)>(objc_msgSend)(mrui_ornamentsItem, NSSelectorFromString(@"setOrnaments:"), @[
        self.menuOrnament
    ]);
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        [self.captureService.captureSession startRunning];
        
        if (AVCaptureDevice *defaultVideoDevice = self.captureService.defaultVideoDevice) {
            [self.captureService queue_addCaptureDevice:defaultVideoDevice];
        }
    });
}

- (XRCaptureService *)captureService {
    if (auto captureService = _captureService) return [[captureService retain] autorelease];
    
    XRCaptureService *captureService = [XRCaptureService new];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdatePreviewLayer:) name:XRCaptureServiceUpdatedPreviewLayerNotificationName object:captureService];
    
    _captureService = [captureService retain];
    return [captureService autorelease];
}

- (XRCaptureVideoPreviewView *)previewView {
    return static_cast<XRCaptureVideoPreviewView *>(self.view);
}

- (XRCamMenuViewController *)menuViewController {
    if (auto menuViewController = _menuViewController) return menuViewController;
    
    XRCamMenuViewController *menuViewController = [[XRCamMenuViewController alloc] initWithCaptureService:self.captureService];
    
    _menuViewController = [menuViewController retain];
    return [menuViewController autorelease];
}

- (id)menuOrnament {
    if (id menuOrnament = _menuOrnament) return [[menuOrnament retain] autorelease];
    
    XRCamMenuViewController *menuViewController = self.menuViewController;
    
    id menuOrnament = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("MRUIPlatterOrnament") alloc], sel_registerName("initWithViewController:"), menuViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(400., 80.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0.5, 0.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(0.5, 1.));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"_setZOffset:"), 50.);
    
    _menuOrnament = [menuOrnament retain];
    
    return menuOrnament;
}

- (void)didUpdatePreviewLayer:(NSNotification *)notification {
    __kindof CALayer * _Nullable previewLayer = self.captureService.queue_previewLayer;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.previewView.previewLayer = previewLayer;
    });
}

@end

#endif
