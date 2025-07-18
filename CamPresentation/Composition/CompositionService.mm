//
//  CompositionService.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/16/25.
//

#import <CamPresentation/CompositionService.h>
#include <objc/runtime.h>
#include <objc/message.h>
#import <CamPresentation/CompositionStorage.h>
#import <CamPresentation/PHImageManager+Category.h>

@interface CompositionService ()
@property (copy, nonatomic, getter=queue_composition, setter=_queue_setComposition:) AVComposition *queue_composition;
@property (retain, nonatomic, getter=_queue_mutableComposition, setter=_queue_setMutableComposition:) AVMutableComposition *queue_mutableComposition;
@end

@implementation CompositionService
@synthesize queue_composition = _queue_composition;
@synthesize queue_mutableComposition = _queue_mutableComposition;

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        _queue = dispatch_queue_create("Composition Service Queue", attr);
        
        _queue_composition = [[AVComposition alloc] init];
        _queue_mutableComposition = [[AVMutableComposition alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    dispatch_release(_queue);
    [_queue_composition release];
    [_queue_mutableComposition release];
    [super dealloc];
}

- (AVComposition *)queue_composition {
    dispatch_assert_queue(self.queue);
    return [[_queue_composition retain] autorelease];
}

- (void)_queue_setComposition:(AVComposition *)composition {
    dispatch_assert_queue(self.queue);
    assert(composition != nil);
    
    [self willChangeValueForKey:@"queue_composition"];
    [_queue_composition release];
    _queue_composition = [composition copy];
    [self didChangeValueForKey:@"queue_composition"];
}

- (AVMutableComposition *)_queue_mutableComposition {
    dispatch_assert_queue(self.queue);
    return _queue_mutableComposition;
}

- (void)_queue_setMutableComposition:(AVMutableComposition *)mutableComposition {
    dispatch_assert_queue(self.queue);
    assert(mutableComposition != nil);
    
    [_queue_mutableComposition release];
    _queue_mutableComposition = [mutableComposition retain];
}

- (void)queue_loadComposition {
    dispatch_assert_queue(self.queue);
    
    AVComposition *composition = CompositionStorage.composition;
    if (composition == nil) return;
    
    AVMutableComposition *mutableComposition = [composition mutableCopy];
    self.queue_mutableComposition = mutableComposition;
    self.queue_composition = mutableComposition;
    [mutableComposition release];
}

- (void)queue_resetComposition {
    dispatch_assert_queue(self.queue);
    
    AVMutableComposition *mutableComposition = [[AVMutableComposition alloc] init];
    self.queue_mutableComposition = mutableComposition;
    self.queue_composition = mutableComposition;
    [mutableComposition release];
}

- (NSProgress *)nonisolated_addVideoSegmentsFromPHAssets:(NSArray<PHAsset *> *)phAssets {    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    
    NSMutableArray<AVAsset *> *avAssets = [[NSMutableArray alloc] init];
    NSProgress *progress = [PHImageManager.defaultManager cp_requestAVAssetForAssets:phAssets options:options resultHandler:^BOOL(AVAsset * _Nonnull asset, AVAudioMix * _Nonnull audioMix, NSDictionary * _Nonnull info, BOOL isLast) {
        [avAssets addObject:asset];
        
        if (isLast) {
            dispatch_async(self.queue, ^{
                [self queue_addVideoSegmentsFromAVAssets:avAssets];
            });
        }
        
        return YES;
    }];
    
    [options release];
    [avAssets release];
    
    return progress;
}

- (void)queue_addVideoSegmentsFromAVAssets:(NSArray<AVAsset *> *)avAssets {
    AVMutableComposition *mutableComposition = self.queue_mutableComposition;
    
    AVMutableCompositionTrack *newVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    assert(newVideoTrack != nil);
    
    NSMutableArray<NSValue *> *timeRanges = [[NSMutableArray alloc] init];
    NSMutableArray<AVAssetTrack *> *tracks = [[NSMutableArray alloc] init];
    
    for (AVAsset *avAsset in avAssets) {
#warning TODO
//        AVAssetTrack *videoTrack = [avAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *videoTrack = reinterpret_cast<NSArray * (*)(id, SEL, id)>(objc_msgSend)(avAsset, sel_registerName("tracksWithMediaType:"), AVMediaTypeVideo).firstObject;
        assert(videoTrack != nil);
        [timeRanges addObject:[NSValue valueWithCMTimeRange:videoTrack.timeRange]];
        [tracks addObject:videoTrack];
    }
    
    NSError * _Nullable error = nil;
    [newVideoTrack insertTimeRanges:timeRanges ofTracks:tracks atTime:kCMTimeZero error:&error];
    assert(error == nil);
    
    [timeRanges release];
    [tracks release];
    
    self.queue_composition = mutableComposition;
}

@end
