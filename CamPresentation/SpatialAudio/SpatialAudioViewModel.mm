//
//  SpatialAudioViewModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/13/25.
//

#import <CamPresentation/SpatialAudioViewModel.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <dlfcn.h>

@interface SpatialAudioViewModel ()
@property (assign, nonatomic) PHImageRequestID requestID;
@property (retain, nonatomic, nullable, getter=_metadataBlob, setter=_setMetadataBlob:) NSData *metadataBlob;
@property (retain, nonatomic, nullable, getter=_audioTrack, setter=_setAudioTrack:) AVAssetTrack *audioTrack;
@property (retain, nonatomic, nullable, getter=_playerItem, setter=_setPlayerItem:) AVPlayerItem *playerItem;
@end

@implementation SpatialAudioViewModel
@synthesize renderingStyle = _renderingStyle;
@synthesize effectIntensity = _effectIntensity;

+ (BOOL)_audioMixSupported {
    void *handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_NOW);
    void *symbol = dlsym(handle, "MGCopyAnswer");
    NSNumber *answer = reinterpret_cast<id (*)(id)>(symbol)(@"DeviceSupportsAudioMix");
    return answer.boolValue;
}

- (instancetype)init {
    assert([SpatialAudioViewModel _audioMixSupported]);
    
    if (self = [super init]) {
        _player = [AVPlayer new];
        _requestID = PHInvalidImageRequestID;
        
#if !TARGET_OS_VISION && !TARGET_OS_SIMULATOR
        _renderingStyle = CNSpatialAudioRenderingStyleStandard;
#else
        _renderingStyle = 7;
#endif
        _effectIntensity = 1.f;
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_player release];
    [_metadataBlob release];
    [_audioTrack release];
    [_playerItem release];
    [super dealloc];
}

- (void)updateWithPHAsset:(PHAsset *)phAsset completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    PHVideoRequestOptions *videoRequestOptions = [PHVideoRequestOptions new];
    videoRequestOptions.version = PHVideoRequestOptionsVersionOriginal;
    videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    videoRequestOptions.networkAccessAllowed = YES;
    
    AVPlayer *player = self.player;
    
    [PHImageManager.defaultManager cancelImageRequest:self.requestID];
    self.requestID = [PHImageManager.defaultManager requestAVAssetForVideo:phAsset options:videoRequestOptions resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (NSError *error = info[PHImageErrorKey]) {
                completionHandler(error);
                return;
            }
            
            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:avAsset];
            [player replaceCurrentItemWithPlayerItem:playerItem];
            
            [avAsset loadTracksWithMediaType:AVMediaTypeMetadata completionHandler:^(NSArray<AVAssetTrack *> * _Nullable metadataTracks, NSError * _Nullable error) {
                if (error != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(error);
                    });
                    return;
                }
                
                NSData * _Nullable metadataBlob = nil;
                for (AVAssetTrack *track in metadataTracks) {
                    metadataBlob = [SpatialAudioViewModel _metadataBlobFromMetadataTrack:track];
                    if (metadataBlob != nil) break;
                }
                assert(metadataBlob != nil);
                
                [avAsset loadTracksWithMediaType:AVMediaTypeAudio completionHandler:^(NSArray<AVAssetTrack *> * _Nullable audioTracks, NSError * _Nullable error) {
                    if (error != nil) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completionHandler(error);
                        });
                        return;
                    }
                    
                    AVAssetTrack * _Nullable audioTrack = nil;
                    for (AVAssetTrack *track in audioTracks) {
                        for (id formatDescription in track.formatDescriptions) {
                            CMFormatDescriptionRef ref = (CMFormatDescriptionRef)formatDescription;
                            if ((CMFormatDescriptionGetMediaType(ref) == kCMMediaType_Audio) && (CMFormatDescriptionGetMediaSubType(ref) == kAudioFormatAPAC)) {
                                audioTrack = track;
                                break;
                            }
                        }
                        
                        if (audioTrack != nil) break;
                    }
                    assert(audioTrack != nil);
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.metadataBlob = metadataBlob;
                        self.audioTrack = audioTrack;
                        self.playerItem = playerItem;
                        [self _didChangeEffect];
                        completionHandler(nil);
                    });
                }];
            }];
            
            [playerItem release];
        });
    }];
    
    [videoRequestOptions release];
}

#if !TARGET_OS_VISION && !TARGET_OS_SIMULATOR
- (CNSpatialAudioRenderingStyle)renderingStyle
#else
- (NSInteger)renderingStyle
#endif
{
    dispatch_assert_queue(dispatch_get_main_queue());
    return _renderingStyle;
}

#if !TARGET_OS_VISION && !TARGET_OS_SIMULATOR
- (void)setRenderingStyle:(CNSpatialAudioRenderingStyle)renderingStyle
#else
- (void)setRenderingStyle:(NSInteger)renderingStyle
#endif
{
    dispatch_assert_queue(dispatch_get_main_queue());
    _renderingStyle = renderingStyle;
    [self _didChangeEffect];
}

- (Float32)effectIntensity {
    dispatch_assert_queue(dispatch_get_main_queue());
    return _effectIntensity;
}

- (void)setEffectIntensity:(Float32)effectIntensity {
    dispatch_assert_queue(dispatch_get_main_queue());
    _effectIntensity = effectIntensity;
    [self _didChangeEffect];
}

- (void)_didChangeEffect {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    assert(self.audioTrack != nil);
    assert(self.metadataBlob != nil);
    assert(self.playerItem != nil);
    
    AVAudioMix *audioMix = [SpatialAudioViewModel _audioMixWithAudioTrack:self.audioTrack metadataBlob:self.metadataBlob renderingStyle:self.renderingStyle effectIntensity:self.effectIntensity];
    self.playerItem.audioMix = audioMix;
}

- (void)_playerItemDidPlayToEndTime:(NSNotification *)notification {
    AVPlayerItem *currentItem = self.player.currentItem;
    if ([currentItem isEqual:notification.object]) {
        [currentItem seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            [self.player play];
        }];
    }
}

// disassembly of __73+[CNAssetSpatialAudioInfo findAssociatedRemixMetadata:completionHandler:]_block_invoke
+ (NSData * _Nullable)_metadataBlobFromMetadataTrack:(AVAssetTrack *)assetTrack {
    AVAsset *asset = assetTrack.asset;
    assert(asset != nil);
    
    AVSampleCursor *cursor = [assetTrack makeSampleCursorWithPresentationTimeStamp:kCMTimeZero];
    assert(cursor != nil);
    AVSampleBufferRequest *request = [[AVSampleBufferRequest alloc] initWithStartCursor:cursor];
    AVSampleBufferGenerator *generator = [[AVSampleBufferGenerator alloc] initWithAsset:asset timebase:nil];
    
    request.direction = AVSampleBufferRequestDirectionForward;
    reinterpret_cast<void (*)(id, SEL, NSInteger)>(objc_msgSend)(request, sel_registerName("setPreferredMinSampleCount:"), 1);
    request.maxSampleCount = 1;
    
    NSError * _Nullable error = nil;
    CMSampleBufferRef sampleBuffer = [generator createSampleBufferForRequest:request error:&error];
    [request release];
    [generator release];
    
    AVTimedMetadataGroup *group = [[AVTimedMetadataGroup alloc] initWithSampleBuffer:sampleBuffer];
    CFRelease(sampleBuffer);
    
    NSUInteger index = [group.items indexOfObjectPassingTest:^BOOL(AVMetadataItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.identifier isEqualToString:@"mdta/com.apple.quicktime.cinematic-audio"];
    }];
    
    if (index == NSNotFound) {
        [group release];
        return nil;
    }
    
    AVMetadataItem *item = [group.items objectAtIndex:index];
    [group release];
    assert(item != nil);
    
    return item.dataValue;
}

// disassembly of -[CNAssetSpatialAudioInfo audioMixWithEffectIntensity:renderingStyle:]
#if !TARGET_OS_VISION && !TARGET_OS_SIMULATOR
+ (AVAudioMix *)_audioMixWithAudioTrack:(AVAssetTrack *)assetTrack metadataBlob:(NSData *)metadataBlob renderingStyle:(CNSpatialAudioRenderingStyle)renderingStyle effectIntensity:(Float32)effectIntensity
#else
+ (AVAudioMix *)_audioMixWithAudioTrack:(AVAssetTrack *)assetTrack metadataBlob:(NSData *)metadataBlob renderingStyle:(NSInteger)renderingStyle effectIntensity:(Float32)effectIntensity
#endif
{
    // x19
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
    // x20
    AVMutableAudioMixInputParameters *inputParameters = [[AVMutableAudioMixInputParameters alloc] init];
    inputParameters.trackID = assetTrack.trackID;
    
    reinterpret_cast<void (*)(id, SEL, Float32, CMTime)>(objc_msgSend)(inputParameters, sel_registerName("setDialogMixBias:atTime:"), effectIntensity, kCMTimeZero);
    // float가 맞음
    reinterpret_cast<void (*)(id, SEL, float, CMTime)>(objc_msgSend)(inputParameters, sel_registerName("setRenderingStyle:atTime:"), renderingStyle, kCMTimeZero);
    
    // x21
    id audioEffect = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("AVAudioMixCinematicAudioEffect"), sel_registerName("cinematicAudioEffectWithData:"), metadataBlob);
    
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(inputParameters, sel_registerName("addEffect:"), audioEffect);
    
    audioMix.inputParameters = @[inputParameters];
    [inputParameters release];
    
    return audioMix;
}

@end
