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
@property (retain, nonatomic, readonly, getter=_colorAppearanceChangeRegistration) id<UITraitChangeRegistration> colorAppearanceChangeRegistration;
@end

@implementation CaptureAudioPreviewView
@synthesize toolbar = _toolbar;
@synthesize menuBarButtonItem = _menuBarButtonItem;

- (instancetype)initWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _audioDevice = [audioDevice retain];
        
        self.backgroundColor = UIColor.systemBackgroundColor;
        
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
        
        _colorAppearanceChangeRegistration = [[self registerForTraitChanges:UITraitCollection.systemTraitsAffectingColorAppearance withTarget:self action:@selector(_colorAppearanceDidChange:)] retain];
        [self _colorAppearanceDidChange:self];
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_audioDevice release];
    [_toolbar release];
    [_menuBarButtonItem release];
    [_colorAppearanceChangeRegistration release];
    [super dealloc];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    
    assert([layer isEqual:self.layer]);
    
    NSArray<AudioWaveLayer *> *audioWaveLayers = self.audioWaveLayers;
    NSUInteger count = audioWaveLayers.count;
    
    if (count == 0) return;
    
    CGRect bounds = layer.bounds;
    UIEdgeInsets safeAreaInsets = self.safeAreaInsets;
    bounds = CGRectMake(CGRectGetMinX(bounds) + safeAreaInsets.left,
                        CGRectGetMinY(bounds) + safeAreaInsets.top,
                        CGRectGetWidth(bounds) - safeAreaInsets.left - safeAreaInsets.right,
                        CGRectGetHeight(bounds) - safeAreaInsets.top - safeAreaInsets.bottom);
    
    CGFloat heightPerLayer = CGRectGetHeight(bounds) / static_cast<CGFloat>(count);
    
    for (NSUInteger idx = 0; idx < count; idx++) {
        AudioWaveLayer *waveLayer = audioWaveLayers[idx];
        waveLayer.frame = CGRectMake(CGRectGetMinX(bounds),
                                     CGRectGetMinY(bounds) + heightPerLayer * static_cast<CGFloat>(idx),
                                     CGRectGetWidth(bounds),
                                     heightPerLayer);
    }
}

- (void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    [self.layer setNeedsLayout];
}

- (NSArray<AudioWaveLayer *> *)audioWaveLayers {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    NSMutableArray<AudioWaveLayer *> *waveLayers = [[NSMutableArray alloc] init];
    
    for (CALayer *sublayer in self.layer.sublayers) {
        if ([sublayer isKindOfClass:[AudioWaveLayer class]]) {
            [waveLayers addObject:static_cast<AudioWaveLayer *>(sublayer)];
        }
    }
    
    return [waveLayers autorelease];
}

- (void)setAudioWaveLayers:(NSArray<AudioWaveLayer *> *)audioWaveLayers {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    NSArray<AudioWaveLayer *> *oldWaveLayer = self.audioWaveLayers;
    NSOrderedCollectionDifference<AudioWaveLayer *> *difference = [audioWaveLayers differenceFromArray:oldWaveLayer withOptions:0];
    
    for (NSOrderedCollectionChange<AudioWaveLayer *> *removal in difference.removals) {
        assert(removal.object != nil);
        [removal.object removeFromSuperlayer];
    }
    
    CALayer *layer = self.layer;
    [self.traitCollection performAsCurrentTraitCollection:^{
        CGColorRef cgColor = UIColor.labelColor.CGColor;
        for (NSOrderedCollectionChange<AudioWaveLayer *> *insertion in difference.insertions) {
            assert(insertion.object != nil);
            insertion.object.waveColor = cgColor;
            [layer insertSublayer:insertion.object atIndex:static_cast<unsigned>(insertion.index)];
        }
    }];
    
    if (difference.hasChanges) {
        [self.layer setNeedsLayout];
    }
}

- (void)_colorAppearanceDidChange:(CaptureAudioPreviewView *)sender {
    [sender.traitCollection performAsCurrentTraitCollection:^{
        CGColorRef cgColor = UIColor.labelColor.CGColor;
        
        for (AudioWaveLayer *waveLayer in self.audioWaveLayers) {
            waveLayer.waveColor = cgColor;
        }
    }];
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
