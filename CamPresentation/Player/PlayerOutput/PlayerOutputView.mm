//
//  PlayerOutputView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/1/24.
//

#import <CamPresentation/PlayerOutputView.h>
#import <CamPresentation/PixelBufferLayerView.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <objc/message.h>
#import <objc/runtime.h>

@interface PlayerOutputView ()
@property (retain, nonatomic, nullable) AVPlayer * _player;
@property (retain, nonatomic, nullable) AVPlayerVideoOutput *_videoOutput;
@property (retain, nonatomic, readonly) SVRunLoop *_renderRunLoop;
@property (retain, nonatomic, readonly) CADisplayLink *_displayLink;
@property (retain, nonatomic, readonly) UIStackView *_stackView;
@end

@implementation PlayerOutputView
@synthesize _renderRunLoop = __renderRunLoop;
@synthesize _displayLink = __displayLink;
@synthesize _stackView = __stackView;

+ (Class)layerClass {
    return [PixelBufferLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self _commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _commonInit];
    }
    
    return self;
}

- (void)dealloc {
    if (AVPlayer *player = __player) {
        [self _removeObserversForPlayer:player];
        [player release];
    }
    [__videoOutput release];
    [__renderRunLoop release];
    __displayLink.paused = YES;
    [__displayLink release];
    [__stackView release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[AVPlayer class]]) {
        if ([keyPath isEqualToString:@"rate"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                assert([self._player isEqual:object]);
                float rate = self._player.rate;
                self._displayLink.paused = (rate == 0.f);
            });
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)_commonInit {
    UIStackView *stackView = self._stackView;
    [self addSubview:stackView];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), stackView);
}

- (void)updateWithPlayer:(AVPlayer *)player specification:(AVVideoOutputSpecification *)specification {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (AVPlayer *oldPlayer = self._player) {
        assert(oldPlayer.videoOutput != nil);
        assert([oldPlayer.videoOutput isEqual:self._videoOutput]);
        oldPlayer.videoOutput = nil;
        [self _removeObserversForPlayer:oldPlayer];
    }
    
    self._player = player;
    [self _addObserversForPlayer:player];
    
    AVPlayerVideoOutput *videoOutput = [[AVPlayerVideoOutput alloc] initWithSpecification:specification];
    player.videoOutput = videoOutput;
    self._videoOutput = videoOutput;
    [videoOutput release];
    
    [self _updatePixelBufferLayerViewCount:specification.preferredTagCollections.count];
}

- (SVRunLoop *)_renderRunLoop {
    if (auto renderRunLoop = __renderRunLoop) return renderRunLoop;
    
    SVRunLoop *renderRunLoop = [[SVRunLoop alloc] initWithThreadName:@"PlayerOutView Render Thread"];
    
    __renderRunLoop = [renderRunLoop retain];
    return [renderRunLoop autorelease];
}

- (CADisplayLink *)_displayLink {
    if (auto displayLink = __displayLink) return displayLink;
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_didTriggerDisplayLink:)];
    
    displayLink.paused = YES;
    [self._renderRunLoop runBlock:^{
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }];
    
    __displayLink = [displayLink retain];
    return displayLink;
}

- (UIStackView *)_stackView {
    if (auto stackView = __stackView) return stackView;
    
    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    
    __stackView = [stackView retain];
    return [stackView autorelease];
}

- (void)_updatePixelBufferLayerViewCount:(NSUInteger)count {
    UIStackView *stackView = self._stackView;
    NSUInteger currentCount = stackView.arrangedSubviews.count;
    
    if (currentCount == count) {
        return;
    } else if (currentCount < count) {
        NSUInteger newCount = count - currentCount;
        
        for (NSUInteger i = 0; i < newCount; i++) {
            PixelBufferLayerView *pixelBufferLayerView = [PixelBufferLayerView new];
            [stackView addArrangedSubview:pixelBufferLayerView];
            [pixelBufferLayerView release];
        }
        
        [stackView updateConstraintsIfNeeded];
    } else if (count < currentCount) {
        NSUInteger deletedCount = currentCount - count;
        
        for (NSUInteger i = 0; i < deletedCount; i++) {
            auto pixelBufferLayerView = static_cast<PixelBufferLayerView *>(stackView.arrangedSubviews.lastObject);
            assert(pixelBufferLayerView != nil);
            [stackView removeArrangedSubview:pixelBufferLayerView];
        }
        
        [stackView updateConstraintsIfNeeded];
    }
}

- (void)_addObserversForPlayer:(AVPlayer *)player {
    assert(player != nil);
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

- (void)_removeObserversForPlayer:(AVPlayer *)player {
    assert(player != nil);
    [player removeObserver:self forKeyPath:@"rate" context:NULL];
}

- (void)_didTriggerDisplayLink:(CADisplayLink *)sender {
    CMTaggedBufferGroupRef _Nullable taggedBufferGroup = [self._videoOutput copyTaggedBufferGroupForHostTime:<#(CMTime)#> presentationTimeStamp:<#(CMTime * _Nullable)#> activeConfiguration:<#(AVPlayerVideoOutputConfiguration * _Nullable * _Nullable)#>];
    NSLog(@"%@", sender);
}

@end
