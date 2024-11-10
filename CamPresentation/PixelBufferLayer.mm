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

@interface PixelBufferLayer () {
    @package CVPixelBufferRef _pixelBuffer;
    @package CAMetalLayer *_metalLayer;
    @package id<MTLDevice> _device;
    @package id<MTLCommandQueue> _commandQueue;
    @package id<MTLRenderPipelineState> _renderPipelineState;
    @package id<MTLSamplerState> _samplerState;
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
    
    CFShow(pixelBuffer);
    
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
//        CVMetalTextureCacheFlush(pixelBufferLayer->_textureCache, 0);
        return;
    }
    
    NSLog(@"Hello!");
    
    id<MTLTexture> _Nullable textureY = CVMetalTextureGetTexture(metalTextureY);
//    CFRelease(metalTextureY);
    
    id<MTLTexture> _Nullable textureCbCr = CVMetalTextureGetTexture(metalTextureCbCr);
//    CFRelease(textureCbCr);
    
    if (!textureY or !textureCbCr) {
        CVMetalTextureCacheFlush(pixelBufferLayer->_textureCache, 0);
        return;
    }
    
    //
    
    CGSize drawableSize = pixelBufferLayer->_metalLayer.drawableSize;
    
    std::pair<std::float_t, std::float_t> ratio {
        drawableSize.width / CVPixelBufferGetWidth(pixelBuffer),
        drawableSize.height / CVPixelBufferGetHeight(pixelBuffer)
    };
    
    std::pair<std::float_t, std::float_t> scale;
    if (ratio.first < ratio.second) { // ratio.first < ratio.second
        scale = {1.f, ratio.first / ratio.second}; // (1.f, ratioX / ratioY)
    } else {
        scale = {ratio.second / ratio.first, 1.f}; // (ratioY / ratioX, 1.f)
    }
    
    std::array<std::float_t, 16> vertexArray {
        -scale.first, -scale.second, 0.f, 1.f,
        scale.first, -scale.second, 0.f, 1.f,
        -scale.first, scale.second, 0.f, 1.f,
        scale.first, scale.second, 0.f, 1.f
    };
    
    id<MTLBuffer> vertexCoordBuffer = [pixelBufferLayer->_device newBufferWithBytes:vertexArray.data() length:vertexArray.size() * sizeof(std::float_t) options:0];
    
    constexpr std::array<std::float_t, 8> textureArray {
        0.f, 1.f,
        1.f, 1.f,
        0.f, 0.f,
        1.f, 0.f
    };
    
    id<MTLBuffer> textureCoordBuffer = [pixelBufferLayer->_device newBufferWithBytes:textureArray.data() length:textureArray.size() * sizeof(std::float_t) options:0];
    
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
    [commandEncoder setFragmentSamplerState:pixelBufferLayer->_samplerState atIndex:0];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [commandEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    
    [pixelBufferLayer release];
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
            CFRunLoopRef runLoop = CFRunLoopGetCurrent();
            CFRunLoopObserverRef observer = (CFRunLoopObserverRef)observerObj;
            assert(!CFRunLoopContainsObserver(runLoop, observer, kCFRunLoopDefaultMode));
            CFRunLoopAddObserver(runLoop, observer, kCFRunLoopDefaultMode);
            
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
            
            MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
            samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
            samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;
            samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
            samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
            id<MTLSamplerState> samplerState = [device newSamplerStateWithDescriptor:samplerDescriptor];
            [samplerDescriptor release];
            
            CVReturn result = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &_textureCache);
            assert(result == kCVReturnSuccess);
            
            _device = device;
            _commandQueue = commandQueue;
            _renderPipelineState = renderPipelineState;
            _samplerState = samplerState;
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
    [_samplerState release];
    CFRelease(_textureCache);
    
    CFRelease(_observer);
    [_runLoop release];
    
    [super dealloc];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    _metalLayer.frame = bounds;
    _metalLayer.drawableSize = self.bounds.size;
}

- (void)updateWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    CFDictionaryRef attributes = CVPixelBufferCopyCreationAttributes(pixelBuffer);
    // Copy the pixel buffer
    CVPixelBufferRef pixelBufferCopy = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, CVPixelBufferGetPixelFormatType(pixelBuffer), attributes, &pixelBufferCopy);
    CFRelease(attributes);
    CVPixelBufferLockBaseAddress(pixelBufferCopy, 0);
    void *copyBaseAddress = CVPixelBufferGetBaseAddress(pixelBufferCopy);
    memcpy(copyBaseAddress, baseAddress, bufferHeight * bytesPerRow);
    
    id pixelBufferObj = (id)pixelBufferCopy;
    
    [_runLoop runBlock:^{
        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        CFRunLoopObserverRef observer = _observer;
        assert(CFRunLoopContainsObserver(runLoop, observer, kCFRunLoopDefaultMode));
        
        if (auto pixelBuffer = _pixelBuffer) {
            CVBufferRelease(pixelBuffer);
        }
        
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)pixelBufferObj;
        CVPixelBufferRetain(pixelBuffer);
        _pixelBuffer = pixelBuffer;
    }];
    
    CVBufferRelease(pixelBufferCopy);
}

@end
