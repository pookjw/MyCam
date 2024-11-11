//
//  PixelBufferLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/10/24.
//

#import <CamPresentation/PixelBufferLayer.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <MetalKit/MetalKit.h>
#include <array>
#include <ranges>

@interface PixelBufferLayer () {
    @package CVPixelBufferRef _pixelBuffer;
    @package CAMetalLayer *_metalLayer;
    @package id<MTLDevice> _device;
    @package id<MTLCommandQueue> _commandQueue;
    @package id<MTLRenderPipelineState> _renderPipelineState;
    CFRunLoopObserverRef _observer;
    CVMetalTextureCacheRef _textureCache;
    SVRunLoop *_runLoop;
}
@end

void PixelBufferLayerRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    auto pixelBufferLayer = static_cast<PixelBufferLayer *>(info);
    [pixelBufferLayer retain];
    
    CVPixelBufferRef pixelBuffer = pixelBufferLayer->_pixelBuffer;
    if (pixelBuffer == nil) return;
    
//    CFShow(pixelBuffer);
    
    id<CAMetalDrawable> _Nullable drawable = pixelBufferLayer->_metalLayer.nextDrawable;
    if (!drawable) return;
    
    CVMetalTextureRef _Nullable metalTextureY = nil;
    CVMetalTextureCacheCreateTextureFromImage(NULL,
                                              pixelBufferLayer->_textureCache,
                                              pixelBuffer,
                                              NULL,
                                              MTLPixelFormatR8Unorm,
                                              CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
                                              CVPixelBufferGetHeightOfPlane(pixelBuffer, 0),
                                              0,
                                              &metalTextureY);
    
    CVMetalTextureRef _Nullable metalTextureCbCr = nil;
    CVMetalTextureCacheCreateTextureFromImage(NULL,
                                              pixelBufferLayer->_textureCache,
                                              pixelBuffer,
                                              NULL,
                                              MTLPixelFormatRG8Unorm,
                                              CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
                                              CVPixelBufferGetHeightOfPlane(pixelBuffer, 1),
                                              1,
                                              &metalTextureCbCr);
    
    if (!metalTextureY or !metalTextureCbCr) {
        CVMetalTextureCacheFlush(pixelBufferLayer->_textureCache, 0);
        return;
    }
    
    NSLog(@"Hello!");
    
    id<MTLTexture> _Nullable textureY = CVMetalTextureGetTexture(metalTextureY);
    CVPixelBufferRelease(metalTextureY);
    id<MTLTexture> _Nullable textureCbCr = CVMetalTextureGetTexture(metalTextureCbCr);
    CVPixelBufferRelease(metalTextureCbCr);
    
    if (!textureY or !textureCbCr) {
        CVMetalTextureCacheFlush(pixelBufferLayer->_textureCache, 0);
        return;
    }
    
    //
    
    float vertexData[16] = {
        -1.0, -1.0,  0.0, 1.0,
        1.0, -1.0,  1.0, 1.0,
        -1.0,  1.0,  0.0, 0.0,
        1.0,  1.0,  1.0, 0.0,
    };
    
    id<MTLBuffer> vertexCoordBuffer = [pixelBufferLayer->_device newBufferWithBytes:vertexData length:sizeof(vertexData) options:0];
    
    float textureData[16] = {
        -1.0, -1.0,  0.0, 1.0,
        1.0, -1.0,  1.0, 1.0,
        -1.0,  1.0,  0.0, 0.0,
        1.0,  1.0,  1.0, 0.0,
    };
    
    id<MTLBuffer> textureCoordBuffer = [pixelBufferLayer->_device newBufferWithBytes:textureData length:sizeof(textureData) options:0];
    
    MTLCommandBufferDescriptor *commandBufferDescriptor = [MTLCommandBufferDescriptor new];
    id<MTLCommandBuffer> commandBuffer = [pixelBufferLayer->_commandQueue commandBufferWithDescriptor:commandBufferDescriptor];
    [commandBufferDescriptor release];
    
    //
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.f, 1.f, 1.f, 1.f);
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderPassDescriptor release];
    [commandEncoder setRenderPipelineState:pixelBufferLayer->_renderPipelineState];
    [commandEncoder setVertexBuffer:vertexCoordBuffer offset:0 atIndex:0];
    [vertexCoordBuffer release];
    [commandEncoder setVertexBuffer:textureCoordBuffer offset:0 atIndex:1];
    [textureCoordBuffer release];
    [commandEncoder setFragmentTexture:textureY atIndex:0];
    [commandEncoder setFragmentTexture:textureCbCr atIndex:1];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [commandEncoder popDebugGroup];
    [commandEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    
    [pixelBufferLayer release];
    
//    [pixelBufferLayer->_metalLayer setNeedsDisplay];
//    [pixelBufferLayer->_metalLayer displayIfNeeded];
}

void PixelBufferLayerRunLoopObserverContextRelease(const void *info) {
//    [static_cast<SVRunLoop *>(info) release];
}

const void * PixelBufferLayerRunLoopObserverContextRetain(const void *info) {
//    return [static_cast<SVRunLoop *>(info) retain];
    return info;
}

@implementation PixelBufferLayer

- (instancetype)init {
    if (self = [super init]) {
        SVRunLoop *runLoop = [[SVRunLoop alloc] initWithThreadName:@"Pixel Buffer Layer"];
        _runLoop = runLoop;
        
        //
        
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
        
        _observer = observer;
        
        //
        
        CAMetalLayer *metalLayer = [CAMetalLayer new];
        metalLayer.frame = self.bounds;
        metalLayer.drawableSize = self.bounds.size;
        [self addSublayer:metalLayer];
        _metalLayer = metalLayer;
        
        //
        
        id observerObj = (id)observer;
        
        [runLoop runBlock:^{
//            CFRunLoopRef runLoop = CFRunLoopGetCurrent();
//            CFRunLoopObserverRef observer = (CFRunLoopObserverRef)observerObj;
//            assert(!CFRunLoopContainsObserver(runLoop, observer, kCFRunLoopDefaultMode));
//            CFRunLoopAddObserver(runLoop, observer, kCFRunLoopDefaultMode);
            
            //
            
            id<MTLDevice> device = MTLCreateSystemDefaultDevice();
            id<MTLCommandQueue> commandQueue = [device newCommandQueue];
            
            NSError * _Nullable error = nil;
            id<MTLLibrary> library = [device newDefaultLibraryWithBundle:[NSBundle bundleForClass:PixelBufferLayer.class] error:&error];
            assert(!error);
            
            MTLFunctionDescriptor *vertexFunctionDescriptor = [MTLFunctionDescriptor new];
            vertexFunctionDescriptor.name = @"pixel_buffer_shader::vertexFunction";
            id<MTLFunction> vertexFunction = [library newFunctionWithDescriptor:vertexFunctionDescriptor error:&error];
            [vertexFunctionDescriptor release];
            assert(!error);
            
            MTLFunctionDescriptor *fragmentFunctionDescriptor = [MTLFunctionDescriptor new];
            fragmentFunctionDescriptor.name = @"pixel_buffer_shader::fragmentFunction";
            id<MTLFunction> fragmentFunction = [library newFunctionWithDescriptor:fragmentFunctionDescriptor error:&error];
            [fragmentFunctionDescriptor release];
            assert(!error);
            
            [library release];
            
            MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
            pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
            pipelineDescriptor.vertexFunction = vertexFunction;
            [vertexFunction release];
            pipelineDescriptor.fragmentFunction = fragmentFunction;
            [fragmentFunction release];
            
            id<MTLRenderPipelineState> renderPipelineState = [device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
            [pipelineDescriptor release];
            assert(!error);
            
            CVReturn result = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &_textureCache);
            assert(result == kCVReturnSuccess);
            
            _device = device;
            _commandQueue = commandQueue;
            _renderPipelineState = renderPipelineState;\
        }];
    }
    
    return self;
}

- (void)dealloc {
    CVBufferRelease(_pixelBuffer);
    [_metalLayer release];
    [_device release];
    [_commandQueue release];
    [_renderPipelineState release];
    CFRelease(_textureCache);
    
    CFRelease(_observer);
    [_runLoop release];
    
    [super dealloc];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    _metalLayer.frame = bounds;
    _metalLayer.drawableSize = CGSizeMake(self.bounds.size.width * self.contentsScale, self.bounds.size.height * self.contentsScale);
}

- (void)updateWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
//    id pixelBufferObj = (id)pixelBuffer;
//    
//    [_runLoop runBlock:^{
//        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
//        CFRunLoopObserverRef observer = _observer;
//        assert(CFRunLoopContainsObserver(runLoop, observer, kCFRunLoopDefaultMode));
//        
//        if (auto pixelBuffer = _pixelBuffer) {
//            CVBufferRelease(pixelBuffer);
//        }
//        
//        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)pixelBufferObj;
//        CVPixelBufferRetain(pixelBuffer);
//        _pixelBuffer = pixelBuffer;
//        
//        PixelBufferLayerRunLoopObserverCallback(NULL, NULL, self);
//    }];
    
    _pixelBuffer = pixelBuffer;
    
    PixelBufferLayerRunLoopObserverCallback(NULL, NULL, self);
}

@end
