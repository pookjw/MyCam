//
//  CinematicEditTimelineDetectionThumbnailVideoCompositor.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicEditTimelineDetectionThumbnailVideoCompositor.h>
#import <Cinematic/Cinematic.h>
#import <CamPresentation/CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction.h>

@implementation CinematicEditTimelineDetectionThumbnailVideoCompositor

- (NSDictionary<NSString *,id> *)sourcePixelBufferAttributes {
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
    auto instruction = static_cast<CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction *>(asyncVideoCompositionRequest.videoCompositionInstruction);
    assert([instruction isKindOfClass:[CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction class]]);
    
    CNCompositionInfo *compositionInfo = instruction.snapshot.compositionInfo;
    
    CVPixelBufferRef imageBuffer = [asyncVideoCompositionRequest sourceFrameByTrackID:compositionInfo.cinematicVideoTrack.trackID];
    if (imageBuffer == NULL) {
        [asyncVideoCompositionRequest finishCancelledRequest];
        return;
    }
    
    /*
     CVPixelBufferRef disparityBuffer = [asyncVideoCompositionRequest sourceFrameByTrackID:cinematicCompositionInfo.cinematicDisparityTrack.trackID];
     */
    
//    CVPixelBufferRef outputBuffer = [asyncVideoCompositionRequest.renderContext newPixelBuffer];
    [asyncVideoCompositionRequest finishWithComposedVideoFrame:imageBuffer];
}

- (BOOL)supportsWideColorSourceFrames {
    return YES;
}

- (BOOL)supportsHDRSourceFrames {
    return YES;
}

@end
