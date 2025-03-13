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

@implementation CinematicEditTimelineDisparityThumbnailVideoCompositor

- (NSDictionary<NSString *,id> *)sourcePixelBufferAttributes {
    return @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_DisparityFloat16)
    };
}

- (NSDictionary<NSString *,id> *)requiredPixelBufferAttributesForRenderContext {
    return @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_DisparityFloat16)
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
    
#warning TODO Pixel Format 변환
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    assert(CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly) == kCVReturnSuccess);
    
    assert((CVPixelBufferGetBytesPerRow(imageBuffer) / width) == sizeof(float16_t));
    
    auto address = reinterpret_cast<float16_t *>(CVPixelBufferGetBaseAddress(imageBuffer));
    assert(address != NULL);
    
    for (size_t h = 0; h < height; h++) {
        for (size_t w = 0; w < width; w++) {
            float16_t disparity = address[h * width + w];
            NSLog(@"%lf", disparity);
        }
        
        if (h == 1) break;
    }
    
    assert(CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly) == kCVReturnSuccess);
    
    //
    
    [asyncVideoCompositionRequest finishWithComposedVideoFrame:imageBuffer];
}

- (BOOL)supportsWideColorSourceFrames {
    return NO;
}

- (BOOL)supportsHDRSourceFrames {
    return NO;
}

@end
