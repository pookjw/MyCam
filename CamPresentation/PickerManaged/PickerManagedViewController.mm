//
//  PickerManagedViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 2/14/25.
//

#import <CamPresentation/PickerManagedViewController.h>
#include <dlfcn.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <PhotosUI/PhotosUI.h>

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */

@interface PickerManagedViewController ()

@end

@implementation PickerManagedViewController

+ (void)load {
    assert(dlopen("/System/Library/PrivateFrameworks/PhotosUIPrivate.framework/PhotosUIPrivate", RTLD_NOW) != NULL);
}

- (void)loadView {
    UIButton *button = [UIButton new];
    
    button.backgroundColor = UIColor.systemBackgroundColor;
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.title = @"Present";
    button.configuration = configuration;
    
    [button addTarget:self action:@selector(_didTriggerButton:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    self.view = button;
    [button release];
}

- (void)_didTriggerButton:(UIButton *)sender {
    PHPickerConfiguration *_configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    id configuration = reinterpret_cast<id (*)(id, SEL, id, id)>(objc_msgSend)([objc_lookUpClass("PUPickerConfiguration") alloc], sel_registerName("initWithPHPickerConfiguration:connection:"), _configuration, nil);
    [_configuration release];
    
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(configuration, sel_registerName("setSupportsInteractiveBarTransition:"), YES);
    
    __kindof UIViewController *contentViewController = reinterpret_cast<id (*)(id, SEL, id, id, id, id, id, id)>(objc_msgSend)([objc_lookUpClass("PUPickerContainerController") alloc], sel_registerName("initWithConfiguration:loadingStatusManager:selectionCoordinator:additionalSelectionState:resizeTaskDescriptorViewModel:actionHandler:"), configuration, nil, nil, nil, nil, nil);
    
    id photosViewConfiguration = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(contentViewController, sel_registerName("photosViewConfiguration"));
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(photosViewConfiguration, sel_registerName("setWantsDynamicTitles:"), YES);
    
    __kindof UIViewController *managedViewController = reinterpret_cast<id (*)(id, SEL, id, id)>(objc_msgSend)([objc_lookUpClass("PUPickerManagedViewController") alloc], sel_registerName("initWithConfiguration:contentViewController:"), configuration, contentViewController);
    [configuration release];
    [contentViewController release];
    
    managedViewController.sheetPresentationController.detents = @[
        [UISheetPresentationControllerDetent mediumDetent],
        [UISheetPresentationControllerDetent largeDetent]
    ];
    managedViewController.sheetPresentationController.largestUndimmedDetentIdentifier = [UISheetPresentationControllerDetent mediumDetent].identifier;
    
    [self presentViewController:managedViewController animated:YES completion:nil];
    [managedViewController release];
}

@end
