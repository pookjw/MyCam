//
//  ARPlayerViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/18/24.
//

#import <TargetConditionals.h>

#if !TARGET_OS_TV

#import <CamPresentation/ARPlayerViewController.h>
#import <CamPresentation/ARPlayerViewControllerVisualProvider.h>
#import <CamPresentation/ARPlayerViewControllerVisualProvider_IOS.h>
#import <CamPresentation/ARPlayerViewControllerVisualProvider_Vision.h>
#import <CamPresentation/AVPlayerVideoOutput+Category.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <objc/message.h>
#import <objc/runtime.h>
#import <ARKit/ARKit.h>

CA_EXTERN_C_BEGIN
BOOL CAFrameRateRangeIsValid(CAFrameRateRange range);
CA_EXTERN_C_END

@interface ARPlayerViewController () <ARPlayerViewControllerVisualProviderDelegate>
@property (retain, nonatomic, readonly) __kindof ARPlayerViewControllerVisualProvider *_visualProvider;
@property (retain, nonatomic, nullable, setter=_setVideoRenderer:) AVSampleBufferVideoRenderer *_videoRenderer;
@property (retain, atomic, nullable) AVPlayerVideoOutput *_playerVideoOutput; // SVRunLoop와 Main Thread에서 접근되므로 atomic
@property (retain, atomic, nullable) AVPlayerItemVideoOutput *_playerItemVideoOutput; // SVRunLoop와 Main Thread에서 접근되므로 atomic
@property (retain, nonatomic, readonly) SVRunLoop *_renderRunLoop;
@property (retain, nonatomic, nullable) CADisplayLink *_displayLink;
@end

@implementation ARPlayerViewController
@synthesize _visualProvider = __visualProvider;
@synthesize _videoRenderer = __videoRenderer;

+ (void)load {
    Protocol *_UIVisualStyleStylable = NSProtocolFromString(@"_UIVisualStyleStylable");
    assert(_UIVisualStyleStylable != NULL);
    assert(class_addProtocol(self, _UIVisualStyleStylable));
}

+ (id)visualStyleRegistryIdentity {
    return self;
}

+ (void)_registerDefaultStylesIfNeeded {
#if TARGET_OS_IOS
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id defaultRegistry = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(objc_lookUpClass("_UIVisualStyleRegistry"), sel_registerName("defaultRegistry"));
        
        reinterpret_cast<void (*)(id, SEL, Class, Class)>(objc_msgSend)(defaultRegistry, sel_registerName("registerVisualStyleClass:forStylableClass:"), ARPlayerViewControllerVisualProvider_IOS.class, self);
    });
#elif TARGET_OS_VISION
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id defaultRegistry = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(objc_lookUpClass("_UIVisualStyleRegistry"), sel_registerName("defaultRegistry"));
        
        reinterpret_cast<void (*)(id, SEL, Class, Class)>(objc_msgSend)(defaultRegistry, sel_registerName("registerVisualStyleClass:forStylableClass:"), ARPlayerViewControllerVisualProvider_Vision.class, self);
    });
#else
    abort();
#endif
}

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
    [__visualProvider release];
    [__videoRenderer release];
    [__playerVideoOutput release];
    [__playerItemVideoOutput release];
    [__displayLink invalidate];
    [__displayLink release];
    [__renderRunLoop release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:AVPlayer.class] and [keyPath isEqualToString:@"currentItem"]) {
        auto player = static_cast<AVPlayer *>(object);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self.player isEqual:player]) return;
            [self _didChangeCurrentItemForPlayer:player];
        });
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self._visualProvider viewDidLoad];
}

- (void)_commonInit {
    __renderRunLoop = [[SVRunLoop alloc] initWithThreadName:@"ARPlayerViewController Render Thread"];
}

- (AVPlayer *)player {
    return self._visualProvider.player;
}

- (void)setPlayer:(AVPlayer *)player {
    if ([self._visualProvider.player isEqual:player]) return;
    
    BOOL usingVideoRenderer = (self._videoRenderer != nil);
    if (usingVideoRenderer) {
        self._videoRenderer = nil;
    }
    
    self._visualProvider.player = player;
    if (usingVideoRenderer) {
        [self _configureVideoRenderer];
    }
}

- (AVSampleBufferVideoRenderer *)_videoRenderer {
    return self._visualProvider.videoRenderer;
}

- (void)_setVideoRenderer:(AVSampleBufferVideoRenderer *)videoRenderer {
    self._visualProvider.videoRenderer = videoRenderer;
}

- (__kindof ARPlayerViewControllerVisualProvider *)_visualProvider {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (auto visualProvider = __visualProvider) return visualProvider;
    
    [ARPlayerViewController _registerDefaultStylesIfNeeded];
    
    id defaultRegistry = reinterpret_cast<id (*)(id, SEL, UIUserInterfaceIdiom)>(objc_msgSend)(objc_lookUpClass("_UIVisualStyleRegistry"), sel_registerName("defaultRegistry"), UIUserInterfaceIdiomPhone);
    
    Class providerClass = reinterpret_cast<Class (*)(id, SEL, id)>(objc_msgSend)(defaultRegistry, sel_registerName("visualStyleClassForStylableClass:"), [ARPlayerViewController class]);
    
    assert(providerClass != nil);
    
    __kindof ARPlayerViewControllerVisualProvider *visualProvider = [(__kindof ARPlayerViewControllerVisualProvider *)[providerClass alloc] initWithPlayerViewController:self];
    
    visualProvider.delegate = self;
    
    __visualProvider = [visualProvider retain];
    return [visualProvider autorelease];
}

- (void)_configureVideoRenderer {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    assert(self.player);
    
    AVSampleBufferVideoRenderer *videoRenderer = [AVSampleBufferVideoRenderer new];
    self._videoRenderer = videoRenderer;
    [videoRenderer release];
}

- (void)_addObserversForPlayer:(AVPlayer *)player {
    [player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

- (void)_removeObserversForPlayer:(AVPlayer *)player {
    [player removeObserver:self forKeyPath:@"currentItem"];
}

- (void)_didChangeCurrentItemForPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    
}

- (void)playerViewControllerVisualProvider:(nonnull ARPlayerViewControllerVisualProvider *)playerViewControllerVisualProvider didSelectRenderType:(ARPlayerRenderType)renderType { 
    switch (renderType) {
        case ARPlayerRenderTypeAVPlayer: {
            if (self._videoRenderer == nil) return;
            self._videoRenderer = nil;
            break;
        }
        case ARPlayerRenderTypeVideoRenderer: {
            if (self._videoRenderer != nil) return;
            [self _configureVideoRenderer];
            break;
        }
        default:
            abort();
    }
}

- (ARPlayerRenderType)rednerTypeWithPlayerViewControllerVisualProvider:(nonnull ARPlayerViewControllerVisualProvider *)playerViewControllerVisualProvider {
    if (self._videoRenderer != nil) {
        return ARPlayerRenderTypeVideoRenderer;
    } else {
        return ARPlayerRenderTypeAVPlayer;
    }
}

@end

#endif
