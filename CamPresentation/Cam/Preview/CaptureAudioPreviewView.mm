//
//  CaptureAudioPreviewView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/CaptureAudioPreviewView.h>
#include <objc/runtime.h>
#include <objc/message.h>
#import <CamPresentation/UIDeferredMenuElement+AudioDevice.h>

@interface CaptureAudioPreviewView ()
@property (retain, nonatomic, readonly, getter=_captureService) CaptureService *captureService;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly, getter=_toolbar) __kindof UIView *toolbar;
#else
@property (retain, nonatomic, readonly, getter=_toolbar) UIToolbar *toolbar;
#endif
@property (retain, nonatomic, readonly, getter=_menuBarButtonItem) UIBarButtonItem *menuBarButtonItem;
@end

@implementation CaptureAudioPreviewView
@synthesize toolbar = _toolbar;
@synthesize menuBarButtonItem = _menuBarButtonItem;

- (instancetype)initWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice audioWaveLayers:(NSSet<AudioWaveLayer *> *)audioWaveLayers {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _audioDevice = [audioDevice retain];
        _audioWaveLayers = [audioWaveLayers copy];
        
        self.backgroundColor = UIColor.systemPinkColor;
        
#if TARGET_OS_TV
        __kindof UIView *toolbar = self.toolbar;
#else
        UIToolbar *toolbar = self.toolbar;
#endif
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:toolbar];
        [NSLayoutConstraint activateConstraints:@[
            [toolbar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [toolbar.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [toolbar.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_audioDevice release];
    [_audioWaveLayers release];
    [_toolbar release];
    [_menuBarButtonItem release];
    [super dealloc];
}

#if TARGET_OS_TV
- (__kindof UIView *)_toolbar {
    if (auto toolbar = _toolbar) return toolbar;
    
    __kindof UIView *toolbar = [objc_lookUpClass("UIToolbar") new];
    
    reinterpret_cast<void (*)(id, SEL, id, BOOL)>(objc_msgSend)(toolbar, sel_registerName("setItems:animated:"), @[
        [UIBarButtonItem flexibleSpaceItem],
        self.menuBarButtonItem
    ], NO);
    
    _toolbar = toolbar;
    return toolbar;
}
#else
- (UIToolbar *)_toolbar {
    if (auto toolbar = _toolbar) return toolbar;
    
    UIToolbar *toolbar = [UIToolbar new];
    
    [toolbar setItems:@[
        [UIBarButtonItem flexibleSpaceItem],
       self.menuBarButtonItem
    ]
             animated:NO];
    
    _toolbar = toolbar;
    return toolbar;
}
#endif

- (UIBarButtonItem *)_menuBarButtonItem {
    if (auto menuBarButtonItem = _menuBarButtonItem) return menuBarButtonItem;
    
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" image:[UIImage systemImageNamed:@"list.bullet"] target:nil action:nil menu:[self _makeMenu]];
    menuBarButtonItem.preferredMenuElementOrder = UIContextMenuConfigurationElementOrderFixed;
    
    _menuBarButtonItem = menuBarButtonItem;
    return menuBarButtonItem;
}

- (UIMenu *)_makeMenu {
    UIDeferredMenuElement *element = [UIDeferredMenuElement cp_audioDeviceElementWithCaptureService:self.captureService audioDevice:self.audioDevice didChangeHandler:nil];
    UIMenu *menu = [UIMenu menuWithChildren:@[element]];
    return menu;
}

@end

#endif
