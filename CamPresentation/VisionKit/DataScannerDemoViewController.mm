//
//  DataScannerDemoViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/10/25.
//

#import <CamPresentation/DataScannerDemoViewController.h>
#import <AVFoundation/AVFoundation.h>
#import <Vision/Vision.h>
#import <CamPresentation/CamPresentation-Swift.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <CamPresentation/ImageVisionView.h>
#import <CamPresentation/SVRunLoop.hpp>

/*
 위치 안 맞는 문제는 CPDataScannerRecognizedItemBounds을 써서 해결해야함
 */

@interface DataScannerDemoViewController () <CPDataScannerViewControllerDelegate>
@property (retain, nonatomic, readonly) CPDataScannerViewController *_dataScannerViewController;
@property (retain, nonatomic, readonly) ImageVisionView *_imageVisionView;
@property (retain, nonatomic, readonly) UIButton *_menuButton;
@end

@implementation DataScannerDemoViewController
@synthesize _dataScannerViewController = __dataScannerViewController;
@synthesize _imageVisionView = __imageVisionView;
@synthesize _menuButton = __menuButton;

- (void)dealloc {
    [__dataScannerViewController removeObserver:self forKeyPath:@"recognizedItems"];
    [__dataScannerViewController release];
    [__imageVisionView release];
    [__menuButton release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[CPDataScannerViewController class]]) {
        if ([keyPath isEqualToString:@"recognizedItems"]) {
            CPDataScannerViewController *dataScannerViewController = object;
            NSArray<__kindof CPDataScannerRecognizedItem *> *recognizedItems = dataScannerViewController.recognizedItems;
            
            NSMutableArray<__kindof VNObservation *> *observations = [NSMutableArray new];
            
            for (__kindof CPDataScannerRecognizedItem *item in recognizedItems) {
                if ([item isKindOfClass:[CPDataScannerRecognizedTextItem class]]) {
                    auto casted = static_cast<CPDataScannerRecognizedTextItem *>(item);
                    [observations addObject:casted.observation];
                } else if ([item isKindOfClass:[CPDataScannerRecognizedBarcodeItem class]]) {
                    auto casted = static_cast<CPDataScannerRecognizedBarcodeItem *>(item);
                    [observations addObject:casted.observation];
                }
            }
            
            self._imageVisionView.imageVisionLayer.observations = observations;
            [observations release];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CPDataScannerViewController *dataScannerViewController = self._dataScannerViewController;
    
    [self addChildViewController:dataScannerViewController];
    
    UIView *dataScannerView = dataScannerViewController.view;
    UIView *view = self.view;
    
    [view addSubview:dataScannerView];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(view, sel_registerName("_addBoundsMatchingConstraintsForView:"), dataScannerView);
    
    [dataScannerViewController didMoveToParentViewController:self];
    
    //
    
    UIView *overlayContainerView = dataScannerViewController.overlayContainerView;
    
    ImageVisionView *imageVisionView = self._imageVisionView;
    imageVisionView.translatesAutoresizingMaskIntoConstraints = NO;
    [overlayContainerView addSubview:imageVisionView];
    [NSLayoutConstraint activateConstraints:@[
        [imageVisionView.topAnchor constraintEqualToAnchor:overlayContainerView.topAnchor],
        [imageVisionView.leadingAnchor constraintEqualToAnchor:overlayContainerView.leadingAnchor],
        [imageVisionView.trailingAnchor constraintEqualToAnchor:overlayContainerView.trailingAnchor],
        [imageVisionView.bottomAnchor constraintEqualToAnchor:overlayContainerView.bottomAnchor]
    ]];
    
    UIButton *menuButton = self._menuButton;
    menuButton.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:menuButton];
    [NSLayoutConstraint activateConstraints:@[
        [menuButton.centerXAnchor constraintEqualToAnchor:view.layoutMarginsGuide.centerXAnchor],
        [menuButton.bottomAnchor constraintEqualToAnchor:view.layoutMarginsGuide.bottomAnchor]
    ]];
}

- (CPDataScannerViewController *)_dataScannerViewController {
    if (auto dataScannerViewController = __dataScannerViewController ) return dataScannerViewController ;
    
    CPDataScannerRecognizedDataType *barcardDataType = [CPDataScannerRecognizedDataType barcodeDataTypeWithSymbologies:@[VNBarcodeSymbologyAztec]];
    
    CPDataScannerViewController *dataScannerViewController = [[CPDataScannerViewController alloc] initWithRecognizedDataTypes:[NSSet setWithObject:barcardDataType]
                                                                                                                 qualityLevel:CPDataScannerQualityLevelAccurate
                                                                                                      recognizesMultipleItems:YES
                                                                                               isHighFrameRateTrackingEnabled:YES
                                                                                                         isPinchToZoomEnabled:YES
                                                                                                            isGuidanceEnabled:YES
                                                                                                        isHighlightingEnabled:YES];
    
    dataScannerViewController.delegate = self;
    [dataScannerViewController addObserver:self forKeyPath:@"recognizedItems" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    
    __dataScannerViewController = [dataScannerViewController retain];
    return [dataScannerViewController autorelease];
}

- (ImageVisionView *)_imageVisionView {
    if (auto imageVisionView = __imageVisionView) return imageVisionView;
    
    SVRunLoop *runLoop = [[SVRunLoop alloc] initWithThreadName:NSStringFromClass([self class])];
    
    ImageVisionView *imageVisionView = [[ImageVisionView alloc] initWithDrawingRunLoop:runLoop];
    [runLoop release];
    
    imageVisionView.imageVisionLayer.shouldDrawOverlay = NO;
    
    __imageVisionView = [imageVisionView retain];
    return [imageVisionView autorelease];
}

- (UIButton *)_menuButton {
    if (auto menuButton = __menuButton) return menuButton;
    
    CPDataScannerViewController *dataScannerViewController = self._dataScannerViewController;
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
        
        //
        
        BOOL isScanning = dataScannerViewController.isScanning;
        if (isScanning) {
            UIAction *action = [UIAction actionWithTitle:@"Stop Scanning" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [dataScannerViewController stopScanning];
            }];
            
            [children addObject:action];
        } else {
            UIAction *action = [UIAction actionWithTitle:@"Start Scanning" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                NSError * _Nullable error = nil;
                [dataScannerViewController startScanningAndReturnError:&error];
                assert(error == nil);
            }];
            
            [children addObject:action];
        }
        
        //
        
        completion(children);
        [children release];
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[element]];
    
    UIButton *menuButton = [UIButton new];
    menuButton.menu = menu;
    menuButton.showsMenuAsPrimaryAction = YES;
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.image = [UIImage systemImageNamed:@"line.3.horizontal"];
    configuration.buttonSize = UIButtonConfigurationSizeLarge;
    
    menuButton.configuration = configuration;
    
    __menuButton = [menuButton retain];
    return [menuButton autorelease];
}

@end
