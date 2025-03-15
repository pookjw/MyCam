//
//  CinematicEditTimelineDetectionThumbnailVideoCompositor.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicEditTimelineDetectionThumbnailVideoCompositor.h>
#import <Cinematic/Cinematic.h>
#import <CamPresentation/CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction.h>
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>

@interface CinematicEditTimelineDetectionThumbnailVideoCompositor ()
@property (class, retain, nonatomic, readonly, getter=_ciContext) CIContext *ciContext;
@end

@implementation CinematicEditTimelineDetectionThumbnailVideoCompositor

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
    NSArray<NSNumber *> *sourcePixelFormatTypes = CNRenderingSession.sourcePixelFormatTypes;
    
    return @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: sourcePixelFormatTypes,
        (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
    };
}

- (NSDictionary<NSString *,id> *)requiredPixelBufferAttributesForRenderContext {
    NSArray<NSNumber *> *sourcePixelFormatTypes = CNRenderingSession.sourcePixelFormatTypes;
    
    return @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: sourcePixelFormatTypes,
        (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
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
    
    //
    
    CGRect detectionRect = CGRectMake(instruction.detection.normalizedRect.origin.x * CVPixelBufferGetWidth(imageBuffer),
                                      instruction.detection.normalizedRect.origin.y * CVPixelBufferGetHeight(imageBuffer),
                                      instruction.detection.normalizedRect.size.width * CVPixelBufferGetWidth(imageBuffer),
                                      instruction.detection.normalizedRect.size.height * CVPixelBufferGetHeight(imageBuffer));
    CGRect detectionTransformedRect = CGRectApplyAffineTransform(detectionRect, instruction.snapshot.renderingSession.preferredTransform);
    
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:imageBuffer options:@{}];
    CIImage *transformedImage = [[[ciImage imageByApplyingTransform:instruction.snapshot.renderingSession.preferredTransform] imageByCroppingToRect:detectionTransformedRect] imageByApplyingTransform:CGAffineTransformTranslate(CGAffineTransformMakeScale(-1., -1.), -detectionTransformedRect.size.width, -detectionTransformedRect.size.height)];
    [ciImage release];
    
    CVPixelBufferRef outputBuffer;
    assert(CVPixelBufferCreate(kCFAllocatorDefault,
                               transformedImage.extent.size.width,
                               transformedImage.extent.size.height,
                               CVPixelBufferGetPixelFormatType(imageBuffer),
                               (CFDictionaryRef)@{(NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}},
                               &outputBuffer) == kCVReturnSuccess);
    [CinematicEditTimelineDetectionThumbnailVideoCompositor.ciContext render:transformedImage toCVPixelBuffer:outputBuffer];
    
    [asyncVideoCompositionRequest finishWithComposedVideoFrame:outputBuffer];
    CVPixelBufferRelease(outputBuffer);
}

- (BOOL)supportsWideColorSourceFrames {
    return YES;
}

- (BOOL)supportsHDRSourceFrames {
    return YES;
}

@end
