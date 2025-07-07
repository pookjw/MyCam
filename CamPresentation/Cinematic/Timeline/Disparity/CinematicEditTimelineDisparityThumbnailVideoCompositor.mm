//
//  CinematicEditTimelineDisparityThumbnailVideoCompositor.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicEditTimelineDisparityThumbnailVideoCompositor.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <Cinematic/Cinematic.h>
#import <CamPresentation/CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction.h>
#include <ranges>
#import <CoreImage/CoreImage.h>
#import <CoreImage/CIFilterBuiltins.h>
#import <UIKit/UIKit.h>

@interface CinematicEditTimelineDisparityThumbnailVideoCompositor ()
@property (class, retain, nonatomic, readonly, getter=_ciContext) CIContext *ciContext;
@end

@implementation CinematicEditTimelineDisparityThumbnailVideoCompositor

+ (CIContext *)_ciContext {
    static CIContext *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        instance = [[CIContext contextWithMTLDevice:device] retain];
        [device release];
    });
    return instance;
}

- (NSDictionary<NSString *,id> *)sourcePixelBufferAttributes {
    return @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_DisparityFloat16),
        (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
    };
}

- (NSDictionary<NSString *,id> *)requiredPixelBufferAttributesForRenderContext {
    return @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB),
        (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
    };
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext {
    
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)asyncVideoCompositionRequest {
    auto instruction = static_cast<CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction *>(asyncVideoCompositionRequest.videoCompositionInstruction);
    assert([instruction isKindOfClass:[CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction class]]);
    
    CNCompositionInfo *compositionInfo = instruction.snapshot.compositionInfo;
    
    CVPixelBufferRef imageBuffer = [asyncVideoCompositionRequest sourceFrameByTrackID:compositionInfo.cinematicDisparityTrack.trackID];
    if (imageBuffer == NULL) {
        [asyncVideoCompositionRequest finishCancelledRequest];
        return;
    }
    
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer);
    assert(pixelFormat == kCVPixelFormatType_DisparityFloat16);
    
    //
    
    //    CIImage *inputImage = [[CIImage alloc] initWithCVPixelBuffer:imageBuffer];
    //    CIFilter<CIColorMonochrome> *filter = [CIFilter colorMonochromeFilter];
    //    filter.inputImage = inputImage;
    //    [inputImage release];
    //    CIImage *outputImage = filter.outputImage;
    //
    //    CVPixelBufferRef outputBuffer = [asyncVideoCompositionRequest.renderContext newPixelBuffer];
    ////    assert(CVPixelBufferCreate(kCFAllocatorDefault,
    ////                               outputImage.extent.size.width,
    ////                               outputImage.extent.size.height,
    ////                               kCVPixelFormatType_32ARGB,
    ////                               (CFDictionaryRef)@{(NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}},
    ////                               &outputBuffer) == kCVReturnSuccess);
    //    [self.ciContext render:outputImage toCVPixelBuffer:outputBuffer];
    //    [asyncVideoCompositionRequest finishWithComposedVideoFrame:outputBuffer];
    //    CVPixelBufferRelease(outputBuffer);
    
    size_t disparityWidth = CVPixelBufferGetWidth(imageBuffer);
    size_t disparityHeight = CVPixelBufferGetHeight(imageBuffer);
    
    CVPixelBufferRef outputBuffer;
    assert(CVPixelBufferCreate(kCFAllocatorDefault,
                               disparityWidth,
                               disparityHeight,
                               kCVPixelFormatType_32ARGB,
                               (CFDictionaryRef)@{(NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}},
                               &outputBuffer) == kCVReturnSuccess);
    
    assert(CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly) == kCVReturnSuccess);
    assert(CVPixelBufferLockBaseAddress(outputBuffer, 0) == kCVReturnSuccess);
    
    assert((CVPixelBufferGetBytesPerRow(imageBuffer) / disparityWidth) == sizeof(float16_t));
    assert((CVPixelBufferGetBytesPerRow(outputBuffer) / disparityWidth) == sizeof(float));
    
    auto address = reinterpret_cast<float16_t *>(CVPixelBufferGetBaseAddress(imageBuffer));
    assert(address != NULL);
    
    auto outAddress = reinterpret_cast<uint32_t *>(CVPixelBufferGetBaseAddress(outputBuffer));
    assert(outAddress != NULL);
    
    // https://x.com/_silgen_name/status/1900559085335982108
    for (size_t dh = 0; dh < disparityHeight; dh++) {
        for (size_t dw = 0; dw < disparityWidth; dw++) {
            float16_t disparity = address[dh * disparityWidth + dw];
            auto byteVal = static_cast<uint8_t>(disparity * 255.f);
            uint32_t pixel = (byteVal << 24) | (byteVal << 16) | (byteVal << 8) | 0b11111111;
            outAddress[dh * disparityWidth + dw] = pixel;
        }
    }
    
    assert(CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly) == kCVReturnSuccess);
    assert(CVPixelBufferUnlockBaseAddress(outputBuffer, 0) == kCVReturnSuccess);
    
    //
    
    CVPixelBufferRef transformedBuffer;
    @autoreleasepool {
        CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:outputBuffer];
        CIImage *transformedImage = [ciImage imageByApplyingTransform:instruction.snapshot.renderingSession.preferredTransform];
        [ciImage release];
        CIImage *translatedImage_1 = [transformedImage imageByApplyingTransform:CGAffineTransformTranslate(CGAffineTransformMakeScale(-1., -1.), transformedImage.extent.size.width, transformedImage.extent.size.height)];
        
        CIImage *translatedImage_2 = [translatedImage_1 imageByApplyingTransform:CGAffineTransformMakeTranslation(-translatedImage_1.extent.origin.x,
                                                                                                                -translatedImage_1.extent.origin.y)];
        
        assert(CVPixelBufferCreate(kCFAllocatorDefault,
                                   translatedImage_2.extent.size.width,
                                   translatedImage_2.extent.size.height,
                                   CVPixelBufferGetPixelFormatType(outputBuffer),
                                   (CFDictionaryRef)@{(NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}},
                                   &transformedBuffer) == kCVReturnSuccess);
        [CinematicEditTimelineDisparityThumbnailVideoCompositor.ciContext render:translatedImage_2 toCVPixelBuffer:transformedBuffer];
    }
    CVBufferRelease(outputBuffer);
    
    [asyncVideoCompositionRequest finishWithComposedVideoFrame:transformedBuffer];
    CVBufferRelease(transformedBuffer);
}

- (void)cancelAllPendingVideoCompositionRequests {
}

- (BOOL)supportsWideColorSourceFrames {
    return NO;
}

- (BOOL)supportsHDRSourceFrames {
    return NO;
}

@end

#endif
