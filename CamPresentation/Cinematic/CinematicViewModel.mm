//
//  CinematicViewModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicViewModel.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/Constants.h>
#import <CamPresentation/CinematicVideoCompositor.h>
#import <CamPresentation/CinematicVideoCompositionInstruction.h>
#import <Metal/Metal.h>

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */
AVF_EXPORT AVMediaType const AVMediaTypeVisionData;
AVF_EXPORT AVMediaType const AVMediaTypePointCloudData;
AVF_EXPORT AVMediaType const AVMediaTypeCameraCalibrationData;

@interface CinematicViewModel ()
@property (retain, nonatomic, readonly, getter=_isolated_commandQueue) id<MTLCommandQueue> isolated_commandQueue;
@property (retain, nonatomic, setter=_isolated_setSnapshot:) CinematicSnapshot *isolated_snapshot;
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
    
//    NSLog(@"%@", AVMediaTypeAuxiliaryPicture);
    
    NSError * _Nullable error = nil;
    [compositionInfo insertTimeRange:data.cnAssetInfo.timeRange ofCinematicAssetInfo:data.cnAssetInfo atTime:kCMTimeZero error:&error];
    assert(error == nil);
    
    CinematicVideoCompositionInstruction *instruction = [[CinematicVideoCompositionInstruction alloc] initWithRenderingSession:renderingSession compositionInfo:compositionInfo script:data.cnScript fNumber:data.cnScript.fNumber editMode:YES];
    [renderingSession release];
    
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
    
    CinematicSnapshot *snapshot = [[CinematicSnapshot alloc] initWithComposition:composition videoComposition:videoComposition assetData:data];
    [composition release];
    [videoComposition release];
    self.isolated_snapshot = snapshot;
    [snapshot release];
}

- (void)isolated_changeFocusAtNormalizedPoint:(CGPoint)normalizedPoint atTime:(CMTime)time strongDecision:(BOOL)strongDecision {
    abort();
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

@end
