//
//  PlayerSampleBufferProvider.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/15/24.
//

#import <CamPresentation/PlayerSampleBufferProvider.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <CamPresentation/AVPlayerVideoOutput+Category.h>
#import <QuartzCore/QuartzCore.h>

@interface PlayerSampleBufferProvider ()
@property (retain, nonatomic, nullable) AVPlayer *_player;
@property (copy, nonatomic, nullable) void (^_handler)(CMSampleBufferRef sampleBuffer);
@property (retain, nonatomic, readonly) SVRunLoop *_runLoop;
@property (retain, nonatomic, nullable) CADisplayLink *_displayLink;
@end

@implementation PlayerSampleBufferProvider

- (instancetype)initWithPlayer:(AVPlayer *)player handler:(void (^)(CMSampleBufferRef _Nonnull))handler {
    if (self = [super init]) {
        __player = [player retain];
        __handler = [handler copy];
        __runLoop = [[SVRunLoop alloc] initWithThreadName:NSStringFromClass([self class])];
        
        [player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    }
    
    return self;
}

- (void)dealloc {
    [__player release];
    [__handler release];
    [__runLoop release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:AVPlayer.class] and [keyPath isEqualToString:@"currentItem"]) {
        
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)invalidate {
    [__runLoop runBlock:^{
        assert(self._player != nil);
        // TODO
    }];
}

@end
