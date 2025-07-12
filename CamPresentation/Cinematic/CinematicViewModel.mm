//
//  CinematicViewModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicViewModel.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/Constants.h>
#import <CamPresentation/CinematicVideoCompositor.h>
#import <CamPresentation/CinematicVideoCompositionInstruction.h>
#import <CamPresentation/CinematicObjectTracking.h>
#import <Metal/Metal.h>
#import <CamPresentation/CinematicSnapshot+Private.h>

NSNotificationName const CinematicViewModelDidUpdateScriptNotification = @"CinematicViewModelDidUpdateScriptNotification";
NSNotificationName const CinematicViewModelDidUpdateSpatioAudioMixInfoNotification = @"CinematicViewModelDidUpdateSpatioAudioMixInfoNotification";

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */
AVF_EXPORT AVMediaType const AVMediaTypeVisionData;
AVF_EXPORT AVMediaType const AVMediaTypePointCloudData;
AVF_EXPORT AVMediaType const AVMediaTypeCameraCalibrationData;

@interface CinematicViewModel ()
@property (retain, nonatomic, readonly, getter=_isolated_commandQueue) id<MTLCommandQueue> isolated_commandQueue;
@property (retain, nonatomic, setter=_isolated_setSnapshot:) CinematicSnapshot *isolated_snapshot;
@property (assign, nonatomic, getter=_isolated_isChangingFocus, setter=_isolated_setChaingingFocus:) BOOL isolated_changingFocus;
@end

@implementation CinematicViewModel
@synthesize isolated_commandQueue = _isolated_commandQueue;
@synthesize isolated_snapshot = _isolated_snapshot;

+ (id)_createValueSetterWithContainerClassID:(id)classID key:(NSString *)key {
    if ([key isEqualToString:@"isolated_snapshot"]) {
        Method method = class_getInstanceMethod(self, @selector(_isolated_setSnapshot:));
        id setter = reinterpret_cast<id (*)(id, SEL, id, id, Method)>(objc_msgSend)([objc_lookUpClass("NSKeyValueMethodSetter") alloc], sel_registerName("initWithContainerClassID:key:method:"), classID, key, method);
        return [setter autorelease];;
    }
    
    struct objc_super superInfo = { self, [self class] };
    return ((id (*)(struct objc_super *, SEL, id, id))objc_msgSendSuper2)(&superInfo, _cmd, classID, key);
}

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
        _queue = dispatch_queue_create("CinematicViewModel", attr);
    }
    
    return self;
}

- (void)dealloc {
    dispatch_release(_queue);
    [_isolated_commandQueue release];
    [_isolated_snapshot release];
    [super dealloc];
}

- (void)isolated_loadWithData:(CinematicAssetData *)data {
    dispatch_assert_queue(self.queue);
    assert(data != nil);
    
    CNRenderingSessionAttributes *sessionAttributes = data.renderingSessionAttributes;
    CNRenderingSession *renderingSession = [[CNRenderingSession alloc] initWithCommandQueue:self.isolated_commandQueue
                                                                          sessionAttributes:sessionAttributes
                                                                         preferredTransform:data.cnAssetInfo.preferredTransform
                                                                                    quality:CNRenderingQualityExportHigh];
    
    AVMutableComposition *composition = [AVMutableComposition new];
    CNCompositionInfo *compositionInfo = [composition addTracksForCinematicAssetInfo:data.cnAssetInfo preferredStartingTrackID:kCMPersistentTrackID_Invalid];
    
    NSError * _Nullable error = nil;
    [compositionInfo insertTimeRange:data.cnAssetInfo.timeRange ofCinematicAssetInfo:data.cnAssetInfo atTime:kCMTimeZero error:&error];
    assert(error == nil);
    
    for (AVAssetTrack *audioTrack in [data.avAsset tracksWithMediaType:AVMediaTypeAudio]) {
        AVMutableCompositionTrack *newTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        assert(newTrack != nil);
        [newTrack insertTimeRange:audioTrack.timeRange ofTrack:audioTrack atTime:kCMTimeZero error:&error];
        assert(error == nil);
    }
    
    CinematicVideoCompositionInstruction *instruction = [[CinematicVideoCompositionInstruction alloc] initWithRenderingSession:renderingSession compositionInfo:compositionInfo script:data.cnScript editMode:YES];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition new];
    videoComposition.sourceTrackIDForFrameTiming = compositionInfo.frameTimingTrack.trackID;
    videoComposition.sourceSampleDataTrackIDs = compositionInfo.sampleDataTrackIDs;
    videoComposition.customVideoCompositorClass = [CinematicVideoCompositor class];
    videoComposition.renderSize = data.cnAssetInfo.preferredSize;
    videoComposition.instructions = @[instruction];
    [instruction release];
    
    if (data.nominalFrameRate <= 0.f) {
        videoComposition.frameDuration = CMTimeMake(1, 30);
    } else {
        videoComposition.frameDuration = CMTimeMakeWithSeconds(1.f / data.nominalFrameRate, data.naturalTimeScale);
    }
    
    CinematicSnapshot *snapshot = [[CinematicSnapshot alloc] initWithComposition:composition videoComposition:videoComposition compositionInfo:compositionInfo renderingSession:renderingSession assetData:data];
    [composition release];
    [renderingSession release];
    [videoComposition release];
    self.isolated_snapshot = snapshot;
    [snapshot release];
}

- (void)isolated_changeFocusAtNormalizedPoint:(CGPoint)normalizedPoint atTime:(CMTime)time strongDecision:(BOOL)strongDecision {
    dispatch_assert_queue(self.queue);
    
    // AVAssetReader가 하나의 Asset에 동시 접근하는 것이 안 되는듯
    assert(!self.isolated_changingFocus);
    self.isolated_changingFocus = YES;
    
    CGPoint finalPoint = [self _invertedNormalizedPointWithNormalizedPoint:normalizedPoint];
    CinematicSnapshot *snapshot = self.isolated_snapshot;
    
    CNScript *cinematicScript = snapshot.assetData.cnScript;
    float nominalFrameRate = snapshot.assetData.nominalFrameRate;
    CMTimeScale naturalTimeScale = snapshot.assetData.naturalTimeScale;
    
    CMTime tolerance = CMTimeMakeWithSeconds(1.0 / nominalFrameRate, naturalTimeScale);
    
    CNScriptFrame *cinematicScriptFrame = [cinematicScript frameAtTime:time tolerance:tolerance];
    if (cinematicScriptFrame == nil) {
        self.isolated_changingFocus = NO;
        return;
    }
    
    
    NSArray<CNDetection *> *allDetections = cinematicScriptFrame.allDetections;
    NSMutableArray<CNDetection *> *detections = [[NSMutableArray alloc] initWithCapacity:allDetections.count];
    for (CNDetection *detection in allDetections) {
        CGRect rect = detection.normalizedRect;
        if (CGRectContainsPoint(rect, finalPoint)) {
//            if (detection.detectionType == CNDetectionTypeHumanFace) {
//                [detections insertObject:detection atIndex:0];
//                break;
//            } else {
//                [detections addObject:detection];
//            }
            [detections addObject:detection];
        }
    }
    
    if (CNDetection *firstDetection = detections.firstObject) {
        CNDetectionID detectionID = firstDetection.detectionID;
        
        CNDecision *decision = [[CNDecision alloc] initWithTime:cinematicScriptFrame.time detectionID:detectionID strong:strongDecision];
        [cinematicScript addUserDecision:decision];
        [decision release];
    }
    
    [detections release];
    
    CMTimeRange timeRange = CMTimeRangeMake(cinematicScriptFrame.time, CMTimeAdd(cinematicScript.timeRange.start, cinematicScript.timeRange.duration));
    
    CinematicObjectTracking *objectTracking = [[CinematicObjectTracking alloc] initWithCommandQueue:self.isolated_commandQueue];
    [objectTracking handleObjectTrackingWithAssetData:snapshot.assetData pointOfInterest:finalPoint timeRange:timeRange strongDecision:strongDecision];
    [objectTracking release];
    
    self.isolated_changingFocus = NO;
    
    [NSNotificationCenter.defaultCenter postNotificationName:CinematicViewModelDidUpdateScriptNotification object:self];
}

- (void)isolated_changeFNumber:(float)fNumber {
    self.isolated_snapshot.assetData.cnScript.fNumber = fNumber;
    [NSNotificationCenter.defaultCenter postNotificationName:CinematicViewModelDidUpdateScriptNotification object:self];
}

- (void)isolated_enableSpatialAudioMix {
    self.isolated_snapshot.spatialAudioMixEnabled = YES;
    self.isolated_snapshot.spatialAudioMixEffectIntensity = 1.f;
    self.isolated_snapshot.spatialAudioMixRenderingStyle = CNSpatialAudioRenderingStyleCinematic;
    [NSNotificationCenter.defaultCenter postNotificationName:CinematicViewModelDidUpdateSpatioAudioMixInfoNotification object:self];
}

- (void)isolated_disableSpatialAudioMix {
    self.isolated_snapshot.spatialAudioMixEnabled = NO;
    [NSNotificationCenter.defaultCenter postNotificationName:CinematicViewModelDidUpdateSpatioAudioMixInfoNotification object:self];
}

- (void)isolated_setSpatialAudioMixEffectIntensity:(float)spatialAudioMixEffectIntensity {
    self.isolated_snapshot.spatialAudioMixEffectIntensity = spatialAudioMixEffectIntensity;
    [NSNotificationCenter.defaultCenter postNotificationName:CinematicViewModelDidUpdateSpatioAudioMixInfoNotification object:self];
}

- (void)isolated_setSpatialAudioMixRenderingStyle:(CNSpatialAudioRenderingStyle)spatialAudioMixRenderingStyle {
    self.isolated_snapshot.spatialAudioMixRenderingStyle = spatialAudioMixRenderingStyle;
    [NSNotificationCenter.defaultCenter postNotificationName:CinematicViewModelDidUpdateSpatioAudioMixInfoNotification object:self];
}

- (id<MTLCommandQueue>)_isolated_commandQueue {
    dispatch_assert_queue(self.queue);
    
    if (auto isolated_commandQueue = _isolated_commandQueue) return isolated_commandQueue;
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLCommandQueue> isolated_commandQueue = [device newCommandQueue];
    [device release];
    
    _isolated_commandQueue = isolated_commandQueue;
    return isolated_commandQueue;
}

- (CinematicSnapshot *)isolated_snapshot {
    dispatch_assert_queue(self.queue);
    return _isolated_snapshot;
}

- (void)_isolated_setSnapshot:(CinematicSnapshot *)isolated_snapshot {
    dispatch_assert_queue(self.queue);
    [_isolated_snapshot release];
    _isolated_snapshot = [isolated_snapshot retain];
}

- (CGPoint)_invertedNormalizedPointWithNormalizedPoint:(CGPoint)point {
    CGAffineTransform preferredTransform = self.isolated_snapshot.assetData.cnAssetInfo.preferredTransform;
    CGAffineTransform inverseTransform = CGAffineTransformInvert(preferredTransform);
    CGSize naturalSize = self.isolated_snapshot.assetData.cnAssetInfo.naturalSize;
    CGSize preferredSize = self.isolated_snapshot.assetData.cnAssetInfo.preferredSize;
    CGPoint texturePoint = CGPointMake(point.x * preferredSize.width,
                                       point.y * preferredSize.height);
    CGRect textureRect = CGRectMake(texturePoint.x, texturePoint.y, 1., 1.);
    CGRect transformedRect = CGRectApplyAffineTransform(textureRect, inverseTransform);
    CGPoint finalPoint = CGPointMake(transformedRect.origin.x / naturalSize.width,
                                     transformedRect.origin.y / naturalSize.height);
    return finalPoint;
}

@end

#endif
