//
//  VisionKitDemoViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/8/25.
//

#import <CamPresentation/VisionKitDemoViewController.h>
#import <VisionKit/VisionKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface VisionKitDemoViewController () <VNDocumentCameraViewControllerDelegate>
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *_cellRegistration;
@property (retain, nonatomic, readonly) UIBarButtonItem *_dcSettingsBarButtonItem;
@end

@implementation VisionKitDemoViewController
@synthesize _cellRegistration = __cellRegistration;
@synthesize _dcSettingsBarButtonItem = __dcSettingsBarButtonItem;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:listConfiguration];
    [listConfiguration release];
    
    if (self = [super initWithCollectionViewLayout:collectionViewLayout]) {
        
    }
    
    return self;
}

- (void)dealloc {
    [__cellRegistration release];
    [__dcSettingsBarButtonItem release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _cellRegistration];
    self.navigationItem.rightBarButtonItem = self._dcSettingsBarButtonItem;
}

- (UICollectionViewCellRegistration *)_cellRegistration {
    if (auto cellRegistration = __cellRegistration) return cellRegistration;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, id  _Nonnull item) {
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        
        if (indexPath.item == 0) {
            contentConfiguration.text = @"VNDocumentCameraViewController (new)";
        } else if (indexPath.item == 1) {
            contentConfiguration.text = @"VNDocumentCameraViewController (Default)";
        } else if (indexPath.item == 2) {
            contentConfiguration.text = @"VNDocumentCameraViewController (In Process)";
        } else if (indexPath.item == 3) {
            contentConfiguration.text = @"VNDocumentCameraViewController (Remote)";
        } else {
            abort();
        }
        
        cell.contentConfiguration = contentConfiguration;
        
        UICellAccessoryDisclosureIndicator *accessory = [UICellAccessoryDisclosureIndicator new];
        cell.accessories = @[accessory];
        [accessory release];
    }];
    
    __cellRegistration = [cellRegistration retain];
    return cellRegistration;
}

- (UIBarButtonItem *)_dcSettingsBarButtonItem {
    if (auto dcSettingsBarButtonItem = __dcSettingsBarButtonItem) return dcSettingsBarButtonItem;
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        id dcSettings = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(objc_lookUpClass("DCSettings"), sel_registerName("sharedSettings"));
        
        BOOL enableViewService = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(dcSettings, sel_registerName("enableViewService"));
        BOOL finishAfterFirstScan = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(dcSettings, sel_registerName("finishAfterFirstScan"));
        BOOL useDocumentSegmentationRequest = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(dcSettings, sel_registerName("useDocumentSegmentationRequest"));
        double imageQuality = reinterpret_cast<double (*)(id, SEL)>(objc_msgSend)(dcSettings, sel_registerName("imageQuality"));
        
        //
        
        UIAction *enableViewServiceAction = [UIAction actionWithTitle:@"enableViewService" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(dcSettings, sel_registerName("setEnableViewServiceBoxed:"), @(!enableViewService));
        }];
        enableViewServiceAction.state = enableViewService ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        //
        
        UIAction *finishAfterFirstScanAction = [UIAction actionWithTitle:@"finishAfterFirstScan" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(dcSettings, sel_registerName("setFinishAfterFirstScanBoxed:"), @(!finishAfterFirstScan));
        }];
        finishAfterFirstScanAction.state = finishAfterFirstScan ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        //
        
        UIAction *useDocumentSegmentationRequestAction = [UIAction actionWithTitle:@"useDocumentSegmentationRequest" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(dcSettings, sel_registerName("setUseDocumentSegmentationRequestBoxed:"), @(!useDocumentSegmentationRequest));
        }];
        useDocumentSegmentationRequestAction.state = useDocumentSegmentationRequest ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        //
        
        __kindof UIMenuElement *imageQualityElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
            UILabel *label = [UILabel new];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
            label.adjustsFontSizeToFitWidth = YES;
            label.minimumScaleFactor = 0.001;
            label.text = @(imageQuality).stringValue;
            
            UISlider *slider = [UISlider new];
            slider.minimumValue = 0.f;
            slider.maximumValue = 1.f;
            slider.value = imageQuality;
            slider.continuous = YES;
            
            UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                auto slider = static_cast<UISlider *>(action.sender);
                float value = slider.value;
                reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(dcSettings, sel_registerName("setImageQualityBoxed:"), @(value));
            }];
            
            [slider addAction:action forControlEvents:UIControlEventValueChanged];
            
            UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, slider]];
            [label release];
            [slider release];
            stackView.axis = UILayoutConstraintAxisVertical;
            stackView.distribution = UIStackViewDistributionFillEqually;
            stackView.alignment = UIStackViewAlignmentFill;
            
            return [stackView autorelease];
        });
        
        UIAction *resetImageQualityAction = [UIAction actionWithTitle:@"Reset" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(dcSettings, sel_registerName("setImageQualityBoxed:"), @(0.9));
        }];
        
        UIMenu *imageQualityMenu = [UIMenu menuWithTitle:@"Image Quality" children:@[imageQualityElement, resetImageQualityAction]];
        
        //
        
        completion(@[enableViewServiceAction, finishAfterFirstScanAction, useDocumentSegmentationRequestAction, imageQualityMenu]);
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[element]];
    
    UIBarButtonItem *dcSettingsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"DCSettings" menu:menu];
    
    __dcSettingsBarButtonItem = [dcSettingsBarButtonItem retain];
    return [dcSettingsBarButtonItem autorelease];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 4;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueConfiguredReusableCellWithRegistration:self._cellRegistration forIndexPath:indexPath item:[NSNull null]];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        assert(VNDocumentCameraViewController.isSupported);
        
        VNDocumentCameraViewController *viewController = [VNDocumentCameraViewController new];
        viewController.delegate = self;
        
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    } else if (indexPath.item == 1) {
        VNDocumentCameraViewController *viewController = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)([VNDocumentCameraViewController class], sel_registerName("newDefaultViewController"));
        viewController.delegate = self;
        
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    } else if (indexPath.item == 2) {
        VNDocumentCameraViewController *viewController = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)([VNDocumentCameraViewController class], sel_registerName("newInProcessViewController"));
        viewController.delegate = self;
        
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    } else if (indexPath.item == 3) {
        VNDocumentCameraViewController *viewController = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)([VNDocumentCameraViewController class], sel_registerName("newViewServiceViewController"));
        viewController.delegate = self;
        
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    } else {
        abort();
    }
}

- (void)documentCameraViewControllerDidCancel:(VNDocumentCameraViewController *)controller {
    [controller.navigationController popViewControllerAnimated:YES];
}

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller didFailWithError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:doneAction];
    
    [controller presentViewController:alertController animated:YES completion:nil];
}

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller didFinishWithScan:(VNDocumentCameraScan *)scan {
#warning TODO
    abort();
}

@end
