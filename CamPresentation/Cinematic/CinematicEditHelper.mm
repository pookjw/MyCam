//
//  CinematicEditHelper.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicEditHelper.h>
#import <CoreVideo/CoreVideo.h>
#include <array>

/*
 MTLPixelFormatGBGR422
 */

@interface CinematicEditHelper ()
@property (retain, nonatomic, readonly, getter=_device) id<MTLDevice> device;
@property (assign, nonatomic, readonly, getter=_textureCache) CVMetalTextureCacheRef textureCache;
@property (retain, nonatomic, readonly, getter=_renderPipelineState) id<MTLRenderPipelineState> renderPipelineState;
@end

@implementation CinematicEditHelper

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _device = [device retain];
        assert(CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, device, NULL, &_textureCache) == kCVReturnSuccess);
        
        NSError * _Nullable error = nil;
        id<MTLLibrary> library = [device newDefaultLibraryWithBundle:[NSBundle bundleForClass:[self class]] error:&error];
        assert(error == nil);
        
        id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
        [library release];
        
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
        pipelineStateDescriptor.label = @"Render Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        [vertexFunction release];
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        [fragmentFunction release];
        pipelineStateDescriptor.vertexBuffers[0].mutability = MTLMutabilityImmutable;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
        _renderPipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        [pipelineStateDescriptor release];
        assert(error == nil);
        
        [vertexFunction release];
    }
    
    return self;
}

- (void)dealloc {
    [_device release];
    CFRelease(_textureCache);
    [_renderPipelineState release];
    [super dealloc];
}

- (void)drawRectsForCNScriptFrame:(CNScriptFrame *)cinematicScriptFrame outputBuffer:(CVPixelBufferRef)outputBuffer stringDecision:(BOOL)strongDecision rectDrawCommandBuffer:(id<MTLCommandBuffer>)rectDrawCommandBuffer preferredTransform:(CGAffineTransform)preferredTransform {
    assert(CVPixelBufferGetPixelFormatType(outputBuffer) == kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange);
    
    size_t width = CVPixelBufferGetWidth(outputBuffer);
    size_t height = CVPixelBufferGetHeight(outputBuffer);
    
    id<MTLRenderCommandEncoder> renderEncoder_YFormat;
    
    CVMetalTextureRef image_YFormat;
    assert(CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, outputBuffer, NULL, MTLPixelFormatRGBA16Float, width, height, 0, &image_YFormat) == kCVReturnSuccess);
    assert(image_YFormat != NULL);
    
    id<MTLTexture> texture_YFormat = CVMetalTextureGetTexture(image_YFormat);
    assert(texture_YFormat != nil);
    
    MTLRenderPassDescriptor *renderPassDescriptor_YFormat = [MTLRenderPassDescriptor new];
    renderPassDescriptor_YFormat.colorAttachments[0].texture = texture_YFormat;
    CFRelease(image_YFormat);
    renderPassDescriptor_YFormat.colorAttachments[0].loadAction = MTLLoadActionLoad;
    renderPassDescriptor_YFormat.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    renderEncoder_YFormat = [rectDrawCommandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor_YFormat];
    [renderPassDescriptor_YFormat release];
    
    [renderEncoder_YFormat setRenderPipelineState:_renderPipelineState];
    
    simd::float4 whiteColor { 1.f, 1.f, 1.f, 1.f};
    simd::float4 yellowColor { 1.f, 1.f, 0.f, 1.f };
    simd::float2 focusRectThickness { 5.f / width, 5.f / height };
    simd::float2 nonFocusRectThickness { 2.f / width, 2.f / height };
    focusRectThickness *= 10.f;
    nonFocusRectThickness *= 10.f;
    
    CNDetection *focusDetection = cinematicScriptFrame.focusDetection;
    CGRect focusRect = focusDetection.normalizedRect;
    CGSize textureSize = CGSizeMake(width, height);
    // normalized
    CGRect transformedRect = [self _applyTransformFromRect:focusRect preferredTransform:preferredTransform textureSize:textureSize];
    
    // Draw Focus
    [self _drawRectsWithRenderEncoder:renderEncoder_YFormat color:yellowColor rect:transformedRect strongDecision:strongDecision thickness:focusRectThickness];
    
    // Draw Detections
    NSArray<CNDetection *> *allDetections = cinematicScriptFrame.allDetections;
    for (CNDetection *detection in allDetections) {
        CGRect normalizedRect = detection.normalizedRect;
        
//        if (detection.detectionID != focusDetection.detectionID) {
//            switch (detection.detectionType) {
//                case CNDetectionTypeHumanFace:
//                case CNDetectionTypeHumanHead:
//                case CNDetectionTypeHumanTorso:
//                {
//                    CGRect transformedRect = [self _applyTransformFromRect:normalizedRect preferredTransform:preferredTransform textureSize:textureSize];
//                    [self _drawRectsWithRenderEncoder:renderEncoder color:whiteColor rect:transformedRect strongDecision:NO thickness:nonFocusRectThickness];
//                    break;
//                }
//                default:
//                    break;
//            }
//        }
        CGRect transformedRect = [self _applyTransformFromRect:normalizedRect preferredTransform:preferredTransform textureSize:textureSize];
        [self _drawRectsWithRenderEncoder:renderEncoder_YFormat color:whiteColor rect:transformedRect strongDecision:NO thickness:nonFocusRectThickness];
    }
    
    [renderEncoder_YFormat endEncoding];
}

- (CGRect)_applyTransformFromRect:(CGRect)rect preferredTransform:(CGAffineTransform)preferredTransform textureSize:(CGSize)textureSize __attribute__((objc_direct)) {
    CGRect textureSizeRect = CGRectMake(0., 0., textureSize.width, textureSize.height);
    
    // Transform 이전으로 설정 후 Normalized Rect를 계산한 뒤 Transform 다시 적용할 것
    CGAffineTransform inverseTransform = CGAffineTransformInvert(preferredTransform);
    
    CGSize transformedTextureSize = CGRectApplyAffineTransform(textureSizeRect, inverseTransform).size;
    
    CGRect textureRect = CGRectMake(rect.origin.x * transformedTextureSize.width,
                                    rect.origin.y * transformedTextureSize.height,
                                    rect.size.width * transformedTextureSize.width,
                                    rect.size.height * transformedTextureSize.height);
    
    CGRect transformedRect = CGRectApplyAffineTransform(textureRect, preferredTransform);
    
    CGRect finalRect = CGRectMake(transformedRect.origin.x / textureSize.width,
                                  transformedRect.origin.y / textureSize.height,
                                  transformedRect.size.width / textureSize.width,
                                  transformedRect.size.height / textureSize.height);
    
    return finalRect;
}

- (void)_drawRectsWithRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder color:(simd::float4)color rect:(CGRect)rect strongDecision:(BOOL)strongDecision thickness:(simd::float2)thickness __attribute__((objc_direct)) {
    if (strongDecision) {
        [self _drawStrongDecisionRectWithRenderEncoder:renderEncoder color:color rect:rect thickness:thickness];
    }
    
    /* Weak-decision rectangle */
    
    CGRect edgeRect = CGRectZero;
    
    // Left edge
    edgeRect.origin.x = rect.origin.x - thickness.x;
    edgeRect.origin.y = rect.origin.y;
    edgeRect.size.width = thickness.x;
    edgeRect.size.height = (rect.size.height / 3.) + thickness.y;
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
    edgeRect.origin.y += (rect.size.height * 2. / 3.);
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
    
    // Top edge
    edgeRect.origin.x = rect.origin.x - thickness.x;
    edgeRect.origin.y = rect.origin.y - thickness.y;
    edgeRect.size.width = (rect.size.width / 3.) + (2. * thickness.x);
    edgeRect.size.height = thickness.y;
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
    edgeRect.origin.x += (rect.size.width * 2. / 3.);
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
    
    // Right edge
    edgeRect.origin.x = rect.origin.x + rect.size.width;
    edgeRect.origin.y = rect.origin.y;
    edgeRect.size.width = thickness.x;
    edgeRect.size.height = (rect.size.height / 3.) + thickness.y;
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
    edgeRect.origin.y += (rect.size.height * 2. / 3.);
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
    
    // Bottom edge
    edgeRect.origin.x = rect.origin.x - thickness.x;
    edgeRect.origin.y = rect.origin.y + rect.size.height;
    edgeRect.size.width = (rect.size.width / 3.) + thickness.x;
    edgeRect.size.height = thickness.y;
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
    edgeRect.origin.x += (rect.size.width * 2. / 3.);
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
}

- (void)_drawStrongDecisionRectWithRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder color:(simd::float4)color rect:(CGRect)rect thickness:(simd::float2)thickness __attribute__((objc_direct)) {
    CGRect edgeRect = CGRectZero;
    
    // Left edge
    edgeRect.origin.x = rect.origin.x - thickness.x;
    edgeRect.origin.y = rect.origin.y;
    edgeRect.size.width = thickness.x;
    edgeRect.size.height = rect.size.height + thickness.y;
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
    
    // Top edge
    edgeRect.origin.x = rect.origin.x - thickness.x;
    edgeRect.origin.y = rect.origin.y + rect.size.height;
    edgeRect.size.width = rect.size.height + thickness.x;
    edgeRect.size.height = thickness.y;
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
    
    // Right edge
    edgeRect.origin.x = rect.origin.x + rect.size.width;
    edgeRect.origin.y = rect.origin.y;
    edgeRect.size.width = thickness.x;
    edgeRect.size.height = rect.size.height + thickness.y;
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
    
    // Bottom edge
    edgeRect.origin.x = rect.origin.x - thickness.x;
    edgeRect.origin.y = rect.origin.y - thickness.y;
    edgeRect.size.width = rect.size.width + 2 * thickness.x;
    edgeRect.size.height = thickness.y;
    [self _drawRectWithRenderEncoder:renderEncoder color:color edgeRect:edgeRect];
}

- (void)_drawRectWithRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder color:(simd::float4)color edgeRect:(CGRect)edgeRect __attribute__((objc_direct)) {
    std::array<simd::float2, 4> vertices {
        simd::float2 { static_cast<float>(edgeRect.origin.x), 1.f - static_cast<float>(edgeRect.origin.y) },
        simd::float2 { static_cast<float>(edgeRect.origin.x), 1.f - static_cast<float>(edgeRect.origin.y + edgeRect.size.height) },
        simd::float2 { static_cast<float>(edgeRect.origin.x + edgeRect.size.width), 1.f - static_cast<float>(edgeRect.origin.y) },
        simd::float2 { static_cast<float>(edgeRect.origin.x + edgeRect.size.width), 1.f - static_cast<float>(edgeRect.origin.y + edgeRect.size.height) }
    };
    
    [renderEncoder setVertexBytes:vertices.data() length:sizeof(simd::float2) * vertices.size() atIndex:0];
    [renderEncoder setVertexBytes:&color length:sizeof(simd::float4) atIndex:1];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
}

@end
