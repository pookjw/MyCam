//
//  PixelBufferLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/10/24.
//

#import <CamPresentation/PixelBufferLayer.h>
#import <MetalKit/MetalKit.h>
#import <CamPresentation/SVRunLoop.hpp>

@interface PixelBufferLayer () {
    @package CAMetalLayer *_metalLayer;
    @package id<MTLDevice> _device;
    @package id<MTLCommandQueue> _commandQueue;
    @package id<MTLRenderPipelineState> _renderPipelineState;
    CVMetalTextureCacheRef _textureCache;
    dispatch_semaphore_t _semaphore;
}
@end

@implementation PixelBufferLayer

- (instancetype)initWithLayer:(id)layer {
    assert([layer isKindOfClass:PixelBufferLayer.class]);
    
    if (self = [super initWithLayer:layer]) {
        auto casted = static_cast<PixelBufferLayer *>(layer);
        
        _metalLayer = [casted->_metalLayer retain];
        _device = [casted->_device retain];
        _commandQueue = [casted->_commandQueue retain];
        _renderPipelineState = [casted->_renderPipelineState retain];
        _textureCache = casted->_textureCache;
        CFRetain(_textureCache);
        _semaphore = casted->_semaphore;
        dispatch_retain(_semaphore);
    }
    
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        __block CAMetalLayer *metalLayer;
        dispatch_sync(dispatch_get_main_queue(), ^{
            metalLayer = [CAMetalLayer new];
        });
        
        metalLayer.frame = self.bounds;
        metalLayer.drawableSize = CGSizeMake(self.bounds.size.width * self.contentsScale, self.bounds.size.height * self.contentsScale);
        [self addSublayer:metalLayer];
        _metalLayer = metalLayer;
        
        //
        
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        metalLayer.device = device;
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
        
        MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor new];
        
        vertexDescriptor.attributes[0].format = MTLVertexFormatFloat2;
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].bufferIndex = 0;
        
        vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
        vertexDescriptor.attributes[1].offset = 8;
        vertexDescriptor.attributes[1].bufferIndex = 0;
        
        vertexDescriptor.layouts[0].stride = 16;
        vertexDescriptor.layouts[0].stepRate = 1;
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
        
        MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        pipelineDescriptor.vertexFunction = vertexFunction;
        [vertexFunction release];
        pipelineDescriptor.fragmentFunction = fragmentFunction;
        [fragmentFunction release];
        pipelineDescriptor.vertexDescriptor = vertexDescriptor;
        [vertexDescriptor release];
        
        id<MTLRenderPipelineState> renderPipelineState = [device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
        [pipelineDescriptor release];
        assert(!error);
        
        CVReturn result = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &_textureCache);
        assert(result == kCVReturnSuccess);
        
        _device = device;
        _commandQueue = commandQueue;
        _renderPipelineState = renderPipelineState;
        _semaphore = dispatch_semaphore_create(3);
    }
    
    return self;
}

- (void)dealloc {
    [_metalLayer release];
    [_device release];
    [_commandQueue release];
    [_renderPipelineState release];
    CFRelease(_textureCache);
    dispatch_release(_semaphore);
    
    [super dealloc];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    _metalLayer.frame = bounds;
    _metalLayer.drawableSize = CGSizeMake(CGRectGetWidth(bounds) * self.contentsScale, CGRectGetHeight(bounds) * self.contentsScale);
}

- (void)updateWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (pixelBuffer == nil) return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    id<CAMetalDrawable> _Nullable drawable = _metalLayer.nextDrawable;
    if (!drawable) {
        dispatch_semaphore_signal(_semaphore);
        return;
    }
    
    CVMetalTextureRef _Nullable metalTextureY = nil;
    CVMetalTextureCacheCreateTextureFromImage(NULL,
                                              _textureCache,
                                              pixelBuffer,
                                              NULL,
                                              MTLPixelFormatR8Unorm,
                                              CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
                                              CVPixelBufferGetHeightOfPlane(pixelBuffer, 0),
                                              0,
                                              &metalTextureY);
    
    CVMetalTextureRef _Nullable metalTextureCbCr = nil;
    CVMetalTextureCacheCreateTextureFromImage(NULL,
                                              _textureCache,
                                              pixelBuffer,
                                              NULL,
                                              MTLPixelFormatRG8Unorm,
                                              CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
                                              CVPixelBufferGetHeightOfPlane(pixelBuffer, 1),
                                              1,
                                              &metalTextureCbCr);
    
    if (!metalTextureY or !metalTextureCbCr) {
        dispatch_semaphore_signal(_semaphore);
        return;
    }
    
    id<MTLTexture> _Nullable textureY = CVMetalTextureGetTexture(metalTextureY);
    id<MTLTexture> _Nullable textureCbCr = CVMetalTextureGetTexture(metalTextureCbCr);
    
    if (!textureY or !textureCbCr) {
        CVPixelBufferRelease(metalTextureY);
        CVPixelBufferRelease(metalTextureCbCr);
        dispatch_semaphore_signal(_semaphore);
        return;
    }
    
    //
    
    float vertexData[16] = {
        -1.0, -1.0,  0.0, 1.0,
        1.0, -1.0,  1.0, 1.0,
        -1.0,  1.0,  0.0, 0.0,
        1.0,  1.0,  1.0, 0.0,
    };
    
    id<MTLBuffer> vertexCoordBuffer = [_device newBufferWithBytes:vertexData length:sizeof(vertexData) options:0];
    
    float textureData[16] = {
        -1.0, -1.0,  0.0, 1.0,
        1.0, -1.0,  1.0, 1.0,
        -1.0,  1.0,  0.0, 0.0,
        1.0,  1.0,  1.0, 0.0,
    };
    
    id<MTLBuffer> textureCoordBuffer = [_device newBufferWithBytes:textureData length:sizeof(textureData) options:0];
    
    MTLCommandBufferDescriptor *commandBufferDescriptor = [MTLCommandBufferDescriptor new];
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBufferWithDescriptor:commandBufferDescriptor];
    [commandBufferDescriptor release];
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
        CVPixelBufferRelease(metalTextureY);
        CVPixelBufferRelease(metalTextureCbCr);
        dispatch_semaphore_signal(_semaphore);
    }];
    
    //
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.f, 0.f, 0.f, 1.f);
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderPassDescriptor release];
    [commandEncoder setRenderPipelineState:_renderPipelineState];
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
}

@end
