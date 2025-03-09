//
//  CinematicVideoCompositor.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicVideoCompositor.h>
#import <CamPresentation/CinematicVideoCompositionInstruction.h>
#import <CoreVideo/CoreVideo.h>
#import <CamPresentation/CinematicEditHelper.h>

@interface CinematicVideoCompositor ()
@property (retain, nonatomic, readonly, getter=_helper) CinematicEditHelper *helper;
@end

@implementation CinematicVideoCompositor

- (instancetype)init {
    if (self = [super init]) {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        _helper = [[CinematicEditHelper alloc] initWithDevice:device];
        [device release];
    }
    
    return self;
}

- (void)dealloc {
    [_helper release];
    [super dealloc];
}

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
    auto instruction = static_cast<CinematicVideoCompositionInstruction *>(asyncVideoCompositionRequest.videoCompositionInstruction);
    assert([instruction isKindOfClass:[CinematicVideoCompositionInstruction class]]);
    
    CVPixelBufferRef outputBuffer = [asyncVideoCompositionRequest.renderContext newPixelBuffer];
    
    CNCompositionInfo *cinematicCompositionInfo = instruction.compositionInfo;
    CNRenderingSession *renderingSession = instruction.renderingSession;
    CNScript *cinematicScript = instruction.script;
    
    CVPixelBufferRef imageBuffer = [asyncVideoCompositionRequest sourceFrameByTrackID:cinematicCompositionInfo.cinematicVideoTrack.trackID];
    if (imageBuffer == NULL) {
        CVPixelBufferRelease(outputBuffer);
        NSLog(@"No video pixel buffer");
        [asyncVideoCompositionRequest finishCancelledRequest];
        return;
    }
    
    CVPixelBufferRef disparityBuffer = [asyncVideoCompositionRequest sourceFrameByTrackID:cinematicCompositionInfo.cinematicDisparityTrack.trackID];
    if (disparityBuffer == NULL) {
        CVPixelBufferRelease(outputBuffer);
        NSLog(@"No disparity pixel buffer");
        [asyncVideoCompositionRequest finishCancelledRequest];
        return;
    }
    
    CMSampleBufferRef metadataBuffer = [asyncVideoCompositionRequest sourceSampleBufferByTrackID:cinematicCompositionInfo.cinematicMetadataTrack.trackID];
    if (metadataBuffer == NULL) {
        CVPixelBufferRelease(outputBuffer);
        NSLog(@"No metabuffer");
        [asyncVideoCompositionRequest finishCancelledRequest];
        return;
    }
    
    CNRenderingSessionFrameAttributes *frameAttributes = [[CNRenderingSessionFrameAttributes alloc] initWithSampleBuffer:metadataBuffer sessionAttributes:renderingSession.sessionAttributes];
    assert(frameAttributes != nil);
    frameAttributes.fNumber = instruction.fNumber;
    
    {
        // Find the nearest frame for focus disparity
        CMTime frameTime = asyncVideoCompositionRequest.compositionTime;
        CMTime tolerance = asyncVideoCompositionRequest.renderContext.videoComposition.frameDuration;
        
        if (CNScriptFrame *frame = [cinematicScript frameAtTime:frameTime tolerance:tolerance]) {
            frameAttributes.focusDisparity = frame.focusDisparity;
        }
    }
    
    id<MTLCommandBuffer> commandBuffer = [renderingSession.commandQueue commandBuffer];
    assert(commandBuffer != nil);
    
    [renderingSession encodeRenderToCommandBuffer:commandBuffer
                                  frameAttributes:frameAttributes
                                      sourceImage:imageBuffer
                                  sourceDisparity:disparityBuffer
                                 destinationImage:outputBuffer];
    [frameAttributes release];
    
    if (instruction.editMode) {
        
    }
    
    id outputBufferObject = (id)outputBuffer;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull commandBuffer) {
        assert(commandBuffer.status == MTLCommandBufferStatusCompleted);
        [asyncVideoCompositionRequest finishWithComposedVideoFrame:(CVPixelBufferRef)outputBufferObject];
    }];
    CVPixelBufferRelease(outputBuffer);
    
    [commandBuffer commit];
}

- (BOOL)supportsWideColorSourceFrames {
    return YES;
}

- (BOOL)supportsHDRSourceFrames {
    return YES;
}

@end
