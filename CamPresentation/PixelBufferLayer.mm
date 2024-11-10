//
//  PixelBufferLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/10/24.
//

#import <CamPresentation/PixelBufferLayer.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <MetalKit/MetalKit.h>

void PixelBufferLayerRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    
}

void PixelBufferLayerRunLoopObserverContextRelease(const void *info) {
    [static_cast<SVRunLoop *>(info) release];
}

const void * PixelBufferLayerRunLoopObserverContextRetain(const void *info) {
    return [static_cast<SVRunLoop *>(info) retain];
}

@interface PixelBufferLayer () {
    CVPixelBufferRef _pixelBuffer;
}
@property (retain, nonatomic, readonly) SVRunLoop *runLoop;
@end

@implementation PixelBufferLayer
@synthesize runLoop = _runLoop;

- (void)dealloc {
    if (auto pixelBuffer = _pixelBuffer) {
        CVBufferRelease(pixelBuffer);
    }
    
    [super dealloc];
}

- (void)updateWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    id pixelBufferObj = (id)pixelBuffer;
    
    [self.runLoop runBlock:^{
        if (auto pixelBuffer = _pixelBuffer) {
            CVBufferRelease(pixelBuffer);
        }
        
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)pixelBufferObj;
        CVPixelBufferRetain(pixelBuffer);
        _pixelBuffer = pixelBuffer;
    }];
}

- (SVRunLoop *)runLoop {
    if (auto runLoop = _runLoop) return runLoop;
    
    SVRunLoop *runLoop = [[SVRunLoop alloc] initWithThreadName:@"Pixel Buffer Layer"];
    
    CFRunLoopRef cfRunLoop = runLoop.runLoop;
    
    CFRunLoopObserverContext context {
        .info = reinterpret_cast<void *>(self),
        .release = PixelBufferLayerRunLoopObserverContextRelease,
        .retain = PixelBufferLayerRunLoopObserverContextRetain
    };
    
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                                            kCFRunLoopBeforeWaiting,
                                                            TRUE,
                                                            0,
                                                            PixelBufferLayerRunLoopObserverCallback,
                                                            &context);
    
    CFRunLoopAddObserver(cfRunLoop, observer, kCFRunLoopDefaultMode);
    
    CFRelease(observer);
    
    _runLoop = [runLoop retain];
    return [runLoop autorelease];
}

@end
