//
//  CinematicEditTimelineDisparityThumbnailVideoCompositor.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicEditTimelineDisparityThumbnailVideoCompositor.h>
#import <Cinematic/Cinematic.h>
#import <CamPresentation/CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction.h>
#include <ranges>
#import <CoreImage/CoreImage.h>
#import <CoreImage/CIFilterBuiltins.h>

@interface CinematicEditTimelineDisparityThumbnailVideoCompositor ()
@property (retain, nonatomic, readonly, getter=_ciContext) CIContext *ciContext;
@end

@implementation CinematicEditTimelineDisparityThumbnailVideoCompositor

- (instancetype)init {
    if (self = [super init]) {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        _ciContext = [[CIContext contextWithMTLDevice:device] retain];
        [device release];
    }
    return self;
}

- (void)dealloc {
    [_ciContext release];
    [super dealloc];
}

- (NSDictionary<NSString *,id> *)sourcePixelBufferAttributes {
//    return @{
//        (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_DisparityFloat16)
//    };
    NSArray<NSNumber *> *sourcePixelFormatTypes = CNRenderingSession.sourcePixelFormatTypes;
    
    return @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: sourcePixelFormatTypes
    };
}

- (NSDictionary<NSString *,id> *)requiredPixelBufferAttributesForRenderContext {
    NSArray<NSNumber *> *sourcePixelFormatTypes = CNRenderingSession.destinationPixelFormatTypes;
    
    return @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: sourcePixelFormatTypes
    };
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext {
    
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)asyncVideoCompositionRequest {
    auto instruction = static_cast<CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction *>(asyncVideoCompositionRequest.videoCompositionInstruction);
    assert([instruction isKindOfClass:[CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction class]]);
    
    CNCompositionInfo *compositionInfo = instruction.snapshot.compositionInfo;
    
    CVPixelBufferRef imageBuffer = [asyncVideoCompositionRequest sourceFrameByTrackID:compositionInfo.cinematicVideoTrack.trackID];
    
//    CVPixelBufferRef imageBuffer = [asyncVideoCompositionRequest sourceFrameByTrackID:compositionInfo.cinematicDisparityTrack.trackID];
//    if (imageBuffer == NULL) {
//        [asyncVideoCompositionRequest finishCancelledRequest];
//        return;
//    }
//    
//    OSType pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer);
//    assert(pixelFormat == kCVPixelFormatType_DisparityFloat16);
    
    //
    
    CIImage *inputImage = [[CIImage alloc] initWithCVPixelBuffer:imageBuffer];
    CIFilter<CIColorMonochrome> *filter = [CIFilter colorMonochromeFilter];
    filter.inputImage = inputImage;
    [inputImage release];
    CIImage *outputImage = filter.outputImage;
    
    CVPixelBufferRef outputBuffer;
     assert(CVPixelBufferCreate(kCFAllocatorDefault,
                                                        outputImage.extent.size.width,
                                                        outputImage.extent.size.height,
                                CVPixelBufferGetPixelFormatType(imageBuffer),
                         NULL, &outputBuffer) == kCVReturnSuccess);
    [self.ciContext render:outputImage toCVPixelBuffer:outputBuffer];
    [asyncVideoCompositionRequest finishWithComposedVideoFrame:outputBuffer];
    CVPixelBufferRelease(outputBuffer);
    
//    size_t disparityWidth = CVPixelBufferGetWidth(imageBuffer);
//    size_t disparityHeight = CVPixelBufferGetHeight(imageBuffer);
//    
//    CVPixelBufferRef outputBuffer;
//    assert(CVPixelBufferCreate(kCFAllocatorDefault,
//                               disparityWidth,
//                               disparityHeight,
//                               kCVPixelFormatType_16Gray,
//                               NULL,
//                               &outputBuffer) == kCVReturnSuccess);
//    
//    assert(CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly) == kCVReturnSuccess);
//    assert(CVPixelBufferLockBaseAddress(outputBuffer, 0) == kCVReturnSuccess);
//    
//    assert((CVPixelBufferGetBytesPerRow(imageBuffer) / disparityWidth) == sizeof(float16_t));
//    assert((CVPixelBufferGetBytesPerRow(outputBuffer) / disparityWidth) == sizeof(float16_t));
//    
//    auto address = reinterpret_cast<float16_t *>(CVPixelBufferGetBaseAddress(imageBuffer));
//    assert(address != NULL);
//    
//    auto outAddress = reinterpret_cast<float16_t *>(CVPixelBufferGetBaseAddress(outputBuffer));
//    assert(outAddress != NULL);
//    
////    for (size_t dh = 0; dh < disparityHeight; dh++) {
////        for (size_t dw = 0; dw < disparityWidth * 4; dw++) {
////            float16_t disparity = address[dh * disparityWidth + dw];
////            outAddress[dh * disparityWidth + (dw)] = disparity;
//////            outAddress[dh * disparityWidth + (dw * 4 + 1)] = disparity;
//////            outAddress[dh * disparityWidth + (dw * 4 + 2)] = disparity;
//////            outAddress[dh * disparityWidth + (dw * 4 + 3)] = 1.f;
////        }
////    }
//    memmove(outAddress, address, CVPixelBufferGetBytesPerRow(imageBuffer) * disparityHeight);
//    
//    assert(CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly) == kCVReturnSuccess);
//    assert(CVPixelBufferUnlockBaseAddress(outputBuffer, 0) == kCVReturnSuccess);
//    
//    //
//    
//    [asyncVideoCompositionRequest finishWithComposedVideoFrame:outputBuffer];
//    CVBufferRelease(outputBuffer);
}

- (BOOL)supportsWideColorSourceFrames {
    return NO;
}

- (BOOL)supportsHDRSourceFrames {
    return NO;
}

@end
