//
//  CinematicObjectTracking.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/10/25.
//

#import <CamPresentation/CinematicObjectTracking.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <CamPresentation/CinematicAssetReader.h>
#import <UIKit/UIKit.h>

@interface CinematicObjectTracking ()
@property (retain, nonatomic, readonly, getter=_cinematicObjectTracker) CNObjectTracker *cinematicObjectTracker;
@property (retain, nonatomic, nullable, getter=_cinematicAssetReader, setter=_setCinematicAssetReader:) CinematicAssetReader *cinematicAssetReader;
@end

@implementation CinematicObjectTracking

- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue {
    if (self = [super init]) {
        _cinematicObjectTracker = [[CNObjectTracker alloc] initWithCommandQueue:commandQueue];
    }
    
    return self;
}

- (void)dealloc {
    [_cinematicObjectTracker release];
    [_cinematicAssetReader release];
    [super dealloc];
}

- (void)handleObjectTrackingWithAssetData:(CinematicAssetData *)cinematicAssetData pointOfInterest:(CGPoint)pointOfInterest timeRange:(CMTimeRange)timeRange strongDecision:(BOOL)strongDecision {
    CinematicAssetReader *cinematicAssetReader = [[CinematicAssetReader alloc] initWithAssetData:cinematicAssetData];
    
    [cinematicAssetReader setupReadingWithTimeRange:timeRange];
    
    self.cinematicAssetReader = cinematicAssetReader;
    
    BOOL result = [self findObjectAndStartTrackingWithPointOfInterest:pointOfInterest];
    if (!result) {
        [cinematicAssetReader cancelReading];
        self.cinematicAssetReader = nil;
        [cinematicAssetReader release];
        return;
    }
    
    //
    
    CinematicSampleBuffer *cinematicSampleBuffer = [cinematicAssetReader nextSampleBuffer];
    while (CVPixelBufferRef imageBuffer = cinematicSampleBuffer.imageBuffer) {
        CVPixelBufferRef disparityBuffer = cinematicSampleBuffer.disparityBuffer;
        assert(disparityBuffer != NULL);
        CMTime presentationTimestamp = cinematicSampleBuffer.presentationTimestamp;
        assert(CMTIME_IS_VALID(presentationTimestamp));
        
        if (CNBoundsPrediction *objectPrediction = [_cinematicObjectTracker continueTrackingAt:presentationTimestamp sourceImage:imageBuffer sourceDisparity:disparityBuffer]) {
            if (CGRectIsEmpty(objectPrediction.normalizedBounds)) {
                break;
            }
        } else {
            break;
        }
        
        [cinematicSampleBuffer release];
        cinematicSampleBuffer = [cinematicAssetReader nextSampleBuffer];
    }
    [cinematicSampleBuffer release];
    
    //
    
    CNDetectionTrack *detectionTrack = [_cinematicObjectTracker finishDetectionTrack];
    CNDetectionID detectionID = [cinematicAssetData.cnScript addDetectionTrack:detectionTrack];
    assert([CNDetection isValidDetectionID:detectionID]);
    assert([CNDetection isValidDetectionID:detectionTrack.detectionID]);
    CNDetectionTrack *newTrack = [cinematicAssetData.cnScript detectionTrackForID:detectionID];
    assert([CNDetection isValidDetectionID:newTrack.detectionID]);
    CNDecision *cinematicDecision = [[CNDecision alloc] initWithTime:timeRange.start detectionID:detectionID strong:strongDecision];
    
    result = [cinematicAssetData.cnScript addUserDecision:cinematicDecision];
    [cinematicDecision release];
    
    if (result) {
        NSLog(@"Added detection successfully");
    }
    
    [cinematicAssetReader cancelReading];
    [cinematicAssetReader release];
    self.cinematicAssetReader = nil;
}

- (BOOL)findObjectAndStartTrackingWithPointOfInterest:(CGPoint)pointOfInterest {
    CinematicAssetReader *cinematicAssetReader = self.cinematicAssetReader;
    assert(cinematicAssetReader != nil);
    
    CinematicSampleBuffer *cinamaticSampleBuffer = [cinematicAssetReader nextSampleBuffer];
    assert(cinamaticSampleBuffer != nil);
    
    CVPixelBufferRef imageBuffer = cinamaticSampleBuffer.imageBuffer;
    assert(imageBuffer != NULL);
    CVPixelBufferRef disparityBuffer = cinamaticSampleBuffer.disparityBuffer;
    assert(disparityBuffer != NULL);
    CMTime presentationTimestamp = cinamaticSampleBuffer.presentationTimestamp;
    assert(CMTIME_IS_VALID(presentationTimestamp));
    
    CNBoundsPrediction *cinematicObjectTrackerPrediction = [_cinematicObjectTracker findObjectAtPoint:pointOfInterest sourceImage:imageBuffer];
    if (cinematicObjectTrackerPrediction == nil) {
        [cinamaticSampleBuffer release];
        NSLog(@"No rect found at %@", NSStringFromCGPoint(pointOfInterest));
        return NO;
    }
    
    CGRect normalizedRect = cinematicObjectTrackerPrediction.normalizedBounds;
    BOOL result = [_cinematicObjectTracker startTrackingAt:presentationTimestamp within:normalizedRect sourceImage:imageBuffer sourceDisparity:disparityBuffer];
    
    if (result) {
        NSLog(@"Start tracking");
    } else {
        NSLog(@"Couldn't start tracking");
    }
    
    [cinamaticSampleBuffer release];
    return result;
}

@end

#endif
