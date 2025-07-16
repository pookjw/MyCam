//
//  AudioWaveLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <CamPresentation/AudioWaveLayer.h>
#import <CamPresentation/SVRunLoop.hpp>
#include <vector>
#include <ranges>
#include <numeric>
#include <cmath>
#include <os/lock.h>

@interface AudioWaveLayer () {
@protected std::vector<float> _amplitudes;
@protected os_unfair_lock _lock;
}
@property (retain, nonatomic, readonly, getter=_runLoop) SVRunLoop *runLoop;
@end

@implementation AudioWaveLayer
@synthesize waveColor = _waveColor;

- (instancetype)init {
    if (self = [super init]) {
        _runLoop = [SVRunLoop.globalRenderRunLoop retain];
        _lock = OS_UNFAIR_LOCK_INIT;
        _waveColor = CGColorCreateSRGB(0., 0., 1., 1.);
    }
    
    return self;
}

- (instancetype)initWithLayer:(id)layer {
    if (self = [super initWithLayer:layer]) {
        auto other = static_cast<AudioWaveLayer *>(layer);
        _runLoop = [other->_runLoop retain];
        _amplitudes = other->_amplitudes;
        _lock = OS_UNFAIR_LOCK_INIT;
        _waveColor = CGColorRetain(other->_waveColor);
    }
    
    return self;
}

- (void)dealloc {
    [_runLoop release];
    CGColorRelease(_waveColor);
    [super dealloc];
}

- (CGColorRef)waveColor {
    CGColorRef waveColor;
    os_unfair_lock_lock(&_lock);
    waveColor = CGColorRetain(_waveColor);
    os_unfair_lock_unlock(&_lock);
    [(id)waveColor autorelease];
    return waveColor;
}

- (void)setWaveColor:(CGColorRef)waveColor {
    os_unfair_lock_lock(&_lock);
    
    CGColorRelease(_waveColor);
    
    if (waveColor == NULL) {
        _waveColor = CGColorCreateSRGB(0., 0., 1., 1.);
    } else {
        _waveColor = CGColorRetain(waveColor);
    }
    
    os_unfair_lock_unlock(&_lock);
}

- (void)drawInContext:(CGContextRef)ctx {
    std::vector<float> amplitudes;
    CGColorRef waveColor;
    os_unfair_lock_lock(&_lock);
    amplitudes = _amplitudes;
    waveColor = CGColorRetain(_waveColor);
    os_unfair_lock_unlock(&_lock);
    
    if (amplitudes.size() == 0) return;
    
    CGContextSetFillColorWithColor(ctx, waveColor);
    CGColorRelease(waveColor);
    
    CGRect bounds = self.bounds;
    CGFloat widthPerSample = CGRectGetWidth(bounds) / 100.;
    
    NSUInteger idx = 0;
    auto rects = std::ranges::views::reverse(amplitudes)
    | std::views::transform([bounds, widthPerSample, &idx](float amplitude) -> CGRect {
        CGFloat height = static_cast<CGFloat>(amplitude) * CGRectGetHeight(bounds);
        
        CGRect frame = CGRectMake(CGRectGetWidth(bounds) - idx * widthPerSample,
                                  CGRectGetMidY(bounds) - height * 0.5,
                                  widthPerSample,
                                  height);
        idx++;
        
        return frame;
    })
    | std::ranges::to<std::vector<CGRect>>();
    
    for (CGRect rect : rects) {
        CGContextFillEllipseInRect(ctx, rect);
    }
//    CGContextFillEllipseInRect(ctx, rects.data(), rects.size());
}

- (void)nonisolated_processSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CMBlockBufferRef _Nullable blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    if (blockBuffer == NULL) return;
    
    size_t length = CMBlockBufferGetDataLength(blockBuffer);
    
    std::vector<float> floatData {};
    floatData.resize(length / sizeof(float));
    
    OSStatus status = CMBlockBufferCopyDataBytes(blockBuffer, 0, length, floatData.data());
    if (status != noErr) return;
    
    auto squares = floatData | std::views::transform([](float f) -> float { return f * f; });
    float rms = std::accumulate(squares.begin(), squares.end(), 0.f) / floatData.size();
    rms = std::sqrt(rms);
    float normalized = std::min(rms, 1.f);
    
    os_unfair_lock_lock(&_lock);
    _amplitudes.push_back(normalized);
    if (_amplitudes.size() > 100) {
        _amplitudes.erase(_amplitudes.begin());
    }
    os_unfair_lock_unlock(&_lock);
    
    [self.runLoop runBlock:^{
        [self setNeedsDisplay];
    }];
}

@end
