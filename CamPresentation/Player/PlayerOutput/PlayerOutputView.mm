//
//  PlayerOutputView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/8/24.
//

#import <CamPresentation/PlayerOutputView.h>
#import <CamPresentation/PixelBufferLayerView.h>
#import <CamPresentation/SampleBufferDisplayLayerView.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <CamPresentation/AVPlayerVideoOutput+Category.h>
#import <CamPresentation/UserTransformView.h>
#import <CoreImage/CoreImage.h>
#import <Metal/Metal.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/AVPlayerItemVideoOutput+Category.h>
#import <QuartzCore/QuartzCore.h>
#include <algorithm>
#include <vector>
#include <ranges>
#include <optional>
#import <CamPresentation/cp_CMSampleBufferCreatePixelBuffer.h>

#warning PixelBufferAttributes 해상도 조정, AVPlayerItem 및 Output쪽 더 보기, 첫 프레임 가져오기 (Slider 조정할 때마다 Frame 업데이트), AVAssetReader와 Audio Track 재생 직접 구현, Rate Speed 선택, AVPlayerLooper 확대시 흐릴려나? 화면만큼만 랜더링해서?

CA_EXTERN_C_BEGIN
BOOL CAFrameRateRangeIsValid(CAFrameRateRange range);
CA_EXTERN_C_END

@interface PlayerOutputView () <UserTransformViewDelegate>
@property (assign, nonatomic, readonly) PlayerOutputLayerType _layerType;
@property (retain, atomic, nullable) AVPlayerVideoOutput *_playerVideoOutput; // SVRunLoop와 Main Thread에서 접근되므로 atomic
@property (retain, atomic, nullable) AVPlayerItemVideoOutput *_playerItemVideoOutput; // SVRunLoop와 Main Thread에서 접근되므로 atomic
@property (copy, atomic, nullable) NSArray<PixelBufferLayer *> *_pixelBufferLayers;
@property (copy, atomic, nullable) NSArray<AVSampleBufferDisplayLayer *> *_sampleBufferDisplayLayers;
@property (retain, nonatomic, readonly) SVRunLoop *_renderRunLoop;
@property (retain, nonatomic, nullable) CADisplayLink *_displayLink;
@property (retain, nonatomic, readonly) UserTransformView *_userTransformView;
@property (retain, nonatomic, readonly) UIStackView *_stackView;
@property (retain, nonatomic, readonly) CIContext *_ciContext;
@end

@implementation PlayerOutputView
@synthesize _renderRunLoop = __renderRunLoop;
@synthesize _userTransformView = __userTransformView;
@synthesize _stackView = __stackView;
@synthesize player = _player;

- (instancetype)initWithFrame:(CGRect)frame layerType:(PlayerOutputLayerType)layerType {
    if (self = [super initWithFrame:frame]) {
        __layerType = layerType;
        [self _commonInit];
    }
    
    return self;
}

- (void)dealloc {
    [__displayLink invalidate];
    [__displayLink release];
    
    if (AVPlayer *player = _player) {
        [self _removeObserversForPlayer:player];
        
        if (AVPlayerVideoOutput *playerVideoOutput = __playerVideoOutput) {
            assert(player.videoOutput != nil);
            assert([player.videoOutput isEqual:playerVideoOutput]);
            player.videoOutput = nil;
        }
        
        [player release];
    }
    
    [__playerVideoOutput release];
    
    if (AVPlayerItemVideoOutput *playerItemVideoOutput = __playerItemVideoOutput) {
        AVPlayerItem *playerItem = playerItemVideoOutput.cp_playerItem;
        assert(playerItem != nil);
        assert([playerItem.outputs containsObject:playerItemVideoOutput]);
        [playerItem removeOutput:playerItemVideoOutput];
        [playerItemVideoOutput release];
    }
    
    [__pixelBufferLayers release];
    [__sampleBufferDisplayLayers release];
    [__renderRunLoop release];
    [__userTransformView release];
    [__stackView release];
    [__ciContext release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[AVPlayer class]]) {
        auto player = static_cast<AVPlayer *>(object);
        
#warning Thread 문제 없는지
        if ([keyPath isEqualToString:@"rate"]) {
            [self _didChangeRateForPlayer:player];
            return;
        } else if ([keyPath isEqualToString:@"currentItem"]) {
            [self _didChangeCurrentItemForPlayer:player change:change];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

// AssetContentView도 bounds로
- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    self._stackView.frame = bounds;
    self._stackView.transform = CGAffineTransformIdentity;
    [self _updateUserTransformView];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    if (self.window) {
        if (self._displayLink != nil) return;
        
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_didTriggerDisplayLink:)];
        
        BOOL isPaused;
        if (AVPlayer *player = self.player) {
            isPaused = (player.rate == 0.f);
        } else {
            isPaused = YES;
        }
        displayLink.paused = isPaused;
        
        [self._renderRunLoop runBlock:^{
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        }];
        //    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        self._displayLink = displayLink;
    } else {
        if (CADisplayLink *displayLink = self._displayLink) {
            [displayLink invalidate];
            displayLink = nil;
        }
    }
}

- (void)_commonInit {
    UIStackView *stackView = self._stackView;
    [self addSubview:stackView];
    
    UserTransformView *userTransformView = self._userTransformView;
    [self addSubview:userTransformView];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), userTransformView);
    
    id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
    CIContext *ciContext = [CIContext contextWithMTLDevice:mtlDevice options:nil];
    [mtlDevice release];
    __ciContext = [ciContext retain];
}

- (AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    return _player;
}

- (void)setPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (AVPlayer *oldPlayer = _player) {
        [self _removeObserversForPlayer:oldPlayer];
        
        if (AVPlayerVideoOutput *playerVideoOutput = self._playerVideoOutput) {
            assert(oldPlayer.videoOutput != nil);
            assert([oldPlayer.videoOutput isEqual:playerVideoOutput]);
            oldPlayer.videoOutput = nil;
            self._playerVideoOutput = nil;
        }
       
        self._displayLink.paused = YES;
        [oldPlayer release];
    }
    
    if (AVPlayerItemVideoOutput *playerItemVideoOutput = self._playerItemVideoOutput) {
        AVPlayerItem *playerItem = playerItemVideoOutput.cp_playerItem;
        assert(playerItem != nil);
        assert([playerItem.outputs containsObject:playerItemVideoOutput]);
        [playerItem removeOutput:playerItemVideoOutput];
        self._playerItemVideoOutput = nil;
    }
    
    if (player == nil) {
        _player = nil;
        [self _updateLayerViewCount:0];
        return;
    }
    
    _player = [player retain];
    [self _addObserversForPlayer:player];
}

- (SVRunLoop *)_renderRunLoop {
    if (auto renderRunLoop = __renderRunLoop) return renderRunLoop;
    
    SVRunLoop *renderRunLoop = [[SVRunLoop alloc] initWithThreadName:@"PlayerOutView Render Thread"];
    
    __renderRunLoop = [renderRunLoop retain];
    return [renderRunLoop autorelease];
}

- (UserTransformView *)_userTransformView {
    if (auto userTransformView = __userTransformView) return userTransformView;
    
    UserTransformView *userTransformView = [[UserTransformView alloc] initWithFrame:self.bounds];
    userTransformView.delegate = self;
    
    __userTransformView = [userTransformView retain];
    return [userTransformView autorelease];
}

- (UIStackView *)_stackView {
    if (auto stackView = __stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithFrame:self.bounds];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    
    __stackView = [stackView retain];
    return [stackView autorelease];
}

- (void)_updateLayerViewCount:(NSUInteger)count {
    PlayerOutputLayerType layerType = self._layerType;
    UIStackView *stackView = self._stackView;
    NSUInteger currentCount = stackView.arrangedSubviews.count;
    
    if (currentCount == count) {
        return;
    } else if (currentCount < count) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        NSUInteger newCount = count - currentCount;
        
        for (NSUInteger i = 0; i < newCount; i++) {
            switch (layerType) {
                case PlayerOutputLayerTypePixelBufferLayer:
                {
                    PixelBufferLayerView *pixelBufferLayerView = [PixelBufferLayerView new];
                    [stackView addArrangedSubview:pixelBufferLayerView];
                    [pixelBufferLayerView release];
                    break;
                }
                case PlayerOutputLayerTypeSampleBufferDisplayLayer:
                {
                    SampleBufferDisplayLayerView *sampleBufferDisplayLayerView = [SampleBufferDisplayLayerView new];
                    [stackView addArrangedSubview:sampleBufferDisplayLayerView];
                    [sampleBufferDisplayLayerView release];
                    break;
                }
                default:
                    abort();
            }
        }
        
        [stackView updateConstraintsIfNeeded];
        
        [CATransaction commit];
    } else if (count < currentCount) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        NSUInteger deletedCount = currentCount - count;
        
        for (NSUInteger i = 0; i < deletedCount; i++) {
            __kindof UIView *arrangedSubview = stackView.arrangedSubviews.lastObject;
            assert(arrangedSubview != nil);
            [stackView removeArrangedSubview:arrangedSubview];
        }
        
        [stackView updateConstraintsIfNeeded];
        
        [CATransaction commit];
    }
    
    switch (layerType) {
        case PlayerOutputLayerTypePixelBufferLayer:
        {
            NSMutableArray<PixelBufferLayer *> *pixelBufferLayers = [[NSMutableArray alloc] initWithCapacity:count];
            for (PixelBufferLayerView *pixelBufferLayerView in stackView.arrangedSubviews) {
                [pixelBufferLayers addObject:pixelBufferLayerView.pixelBufferLayer];
            }
            self._pixelBufferLayers = pixelBufferLayers;
            [pixelBufferLayers release];
            break;
        }
        case PlayerOutputLayerTypeSampleBufferDisplayLayer:
        {
            NSMutableArray<AVSampleBufferDisplayLayer *> *sampleBufferDisplayLayers = [[NSMutableArray alloc] initWithCapacity:count];
            for (SampleBufferDisplayLayerView *sampleBufferDisplayLayerView in stackView.arrangedSubviews) {
                [sampleBufferDisplayLayers addObject:sampleBufferDisplayLayerView.sampleBufferDisplayLayer];
            }
            self._sampleBufferDisplayLayers = sampleBufferDisplayLayers;
            [sampleBufferDisplayLayers release];
            break;
        }
        default:
            abort();
    }
}

- (void)_addObserversForPlayer:(AVPlayer *)player {
    assert(player != nil);
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

- (void)_removeObserversForPlayer:(AVPlayer *)player {
    assert(player != nil);
    [player removeObserver:self forKeyPath:@"rate" context:NULL];
    [player removeObserver:self forKeyPath:@"currentItem"];
}

- (void)_didTriggerDisplayLink:(CADisplayLink *)sender {
    if (AVPlayerVideoOutput *playerVideoOutput = self._playerVideoOutput) {
        CMTime hostTime = CMTimeMake(static_cast<int64_t>(sender.timestamp * USEC_PER_SEC), USEC_PER_SEC);
        
        CMTime presentationTimeStamp;
        AVPlayerVideoOutputConfiguration *activeConfiguration;
        CMTaggedBufferGroupRef _Nullable taggedBufferGroup = [playerVideoOutput copyTaggedBufferGroupForHostTime:hostTime presentationTimeStamp:&presentationTimeStamp activeConfiguration:&activeConfiguration];
        
        if (taggedBufferGroup == NULL) {
            return;
        }
        
        if (id<PlayerOutputViewDelegate> delegate = self.delegate) {
            [delegate playerOutputView:self didUpdatePixelBufferVariant:taggedBufferGroup];
        }
        
        for (CFIndex index : std::views::iota(0, CMTaggedBufferGroupGetCount(taggedBufferGroup))) {
            CMTagCollectionRef tagCollection = CMTaggedBufferGroupGetTagCollectionAtIndex(taggedBufferGroup, index);
            
            CMItemCount tagCollectionCount = CMTagCollectionGetCount(tagCollection);
            
            CMTag *tags = new CMTag[tagCollectionCount];
            CMItemCount numberOfTagsCopied;
            assert(CMTagCollectionGetTags(tagCollection, tags, tagCollectionCount, &numberOfTagsCopied) == kCVReturnSuccess);
            assert(tagCollectionCount == numberOfTagsCopied);
            
            for (const CMTag *tagPtr : std::views::iota(tags, tags + numberOfTagsCopied)) {
                CMTag tag = *tagPtr;
                CMTagCategory category = CMTagGetCategory(tag);
                if (category != kCMTagCategory_StereoView) continue;
                
                CMTagValue value = CMTagGetValue(tag);
                CVPixelBufferRef _Nullable pixelBuffer = CMTaggedBufferGroupGetCVPixelBufferAtIndex(taggedBufferGroup, index);
                if (pixelBuffer == nil) break;
                
                NSInteger viewIndex;
                if (value == kCMStereoView_LeftEye) {
                    viewIndex = 0;
                } else if (value == kCMStereoView_RightEye) {
                    viewIndex = 1;
                } else {
                    abort();
                }
                
                switch (self._layerType) {
                    case PlayerOutputLayerTypePixelBufferLayer:
                    {
                        NSArray<PixelBufferLayer *> *pixelBufferLayers = self._pixelBufferLayers;
                        if (viewIndex < pixelBufferLayers.count) {
                            PixelBufferLayer * pixelBufferLayer = pixelBufferLayers[viewIndex];
                            [pixelBufferLayer updateWithPixelBuffer:pixelBuffer];
                        }
                        break;
                    }
                    case PlayerOutputLayerTypeSampleBufferDisplayLayer:
                    {
                        CMSampleBufferRef sampleBuffer = cp_CMSampleBufferCreatePixelBuffer(pixelBuffer);
                        
                        NSArray<AVSampleBufferDisplayLayer *> *sampleBufferDisplayLayers = self._sampleBufferDisplayLayers;
                        if (viewIndex < sampleBufferDisplayLayers.count) {
                            AVSampleBufferDisplayLayer *sampleBufferDisplayLayer = sampleBufferDisplayLayers[viewIndex];
                            AVSampleBufferVideoRenderer *sampleBufferRenderer = sampleBufferDisplayLayer.sampleBufferRenderer;
                            [sampleBufferRenderer flush];
                            [sampleBufferRenderer enqueueSampleBuffer:sampleBuffer];
                        }
                        
                        CFRelease(sampleBuffer);
                        break;
                    }
                    default:
                        abort();
                }
            }
            
            delete[] tags;
        }
        
        CFRelease(taggedBufferGroup);
    } else if (AVPlayerItemVideoOutput *playerItemVideoOutput = self._playerItemVideoOutput) {
        AVPlayerItem *playerItem = playerItemVideoOutput.cp_playerItem;
        if (playerItem == nil) return;
        
        CMTime currentTime = playerItem.currentTime;
        
        if (![playerItemVideoOutput hasNewPixelBufferForItemTime:currentTime]) {
            return;
        }
        
        CMTime displayItem;
        CVPixelBufferRef _Nullable pixelBuffer = [playerItemVideoOutput copyPixelBufferForItemTime:currentTime itemTimeForDisplay:&displayItem];
        
        if (pixelBuffer) {
            if (id<PlayerOutputViewDelegate> delegate = self.delegate) {
                [delegate playerOutputView:self didUpdatePixelBufferVariant:pixelBuffer];
            }
            
            switch (self._layerType) {
                case PlayerOutputLayerTypePixelBufferLayer:
                {
                    NSArray<PixelBufferLayer *> *pixelBufferLayers = self._pixelBufferLayers;
                    PixelBufferLayer *pixelBufferLayer = pixelBufferLayers.firstObject;
                    if (pixelBufferLayer != nil) {
                        [pixelBufferLayer updateWithPixelBuffer:pixelBuffer];
                    }
                    break;
                }
                case PlayerOutputLayerTypeSampleBufferDisplayLayer:
                {
                    NSArray<AVSampleBufferDisplayLayer *> *sampleBufferDisplayLayers = self._sampleBufferDisplayLayers;
                    AVSampleBufferDisplayLayer *sampleBufferDisplayLayer = sampleBufferDisplayLayers.firstObject;
                    if (sampleBufferDisplayLayer != nil) {
                        CMSampleBufferRef sampleBuffer = cp_CMSampleBufferCreatePixelBuffer(pixelBuffer);
                        
                        AVSampleBufferVideoRenderer *sampleBufferRenderer = sampleBufferDisplayLayer.sampleBufferRenderer;
                        [sampleBufferRenderer flush];
                        [sampleBufferRenderer enqueueSampleBuffer:sampleBuffer];
                        
                        CFRelease(sampleBuffer);
                    }
                    
                    break;
                }
                default:
                    abort();
            }
            
            CVPixelBufferRelease(pixelBuffer);
        }
    }
}

- (void)_didChangeRateForPlayer:(AVPlayer *)player {
    dispatch_async(dispatch_get_main_queue(), ^{
        assert([self.player isEqual:player]);
        float rate = player.rate;
        self._displayLink.paused = (rate == 0.f);
    });
    
    [self _updatePreferredFrameRateRangeWithPlayer:player];
}

- (void)_didChangeCurrentItemForPlayer:(AVPlayer *)player change:(NSDictionary *)change {
    AVPlayerItem * _Nullable currentItem = player.currentItem;
    if (currentItem == nil) return;
    
    [self _updatePreferredFrameRateRangeWithPlayer:player];
    
    //
    
    if (change[NSKeyValueChangeOldKey] != nil and self._playerVideoOutput == nil) {
        assert(self._playerItemVideoOutput != nil);
    }
    
    if (AVPlayerVideoOutput *playerVideoOutput = __playerVideoOutput) {
        assert([player.videoOutput isEqual:playerVideoOutput]);
        player.videoOutput = nil;
        self._playerVideoOutput = nil;
        assert(self._playerItemVideoOutput == nil);
    } else if (AVPlayerItemVideoOutput *playerItemVideoOutput = self._playerItemVideoOutput) {
        AVPlayerItem *oldPlayerItem = change[NSKeyValueChangeOldKey];
        assert(oldPlayerItem != nil);
        assert([oldPlayerItem.outputs containsObject:playerItemVideoOutput]);
        [currentItem removeOutput:playerItemVideoOutput];
        self._playerItemVideoOutput = nil;
    }
    
    assert(self._playerVideoOutput == nil);
    assert(self._playerItemVideoOutput == nil);
    
    //
    
    AVAsset *asset = currentItem.asset;
    
    if (!AVPlayerVideoOutput.cp_isSupported) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self.player isEqual:player]) return;
            if (![self.player.currentItem isEqual:currentItem]) return;
            
            [self _updateLayerViewCount:1];
            [self _updateUserTransformView];
            
            //
            
            assert(self._playerVideoOutput == nil);
            assert(self._playerItemVideoOutput == nil);
            
            AVPlayerItemVideoOutput *playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:nil];
#warning TODO - setup delegate
            self._playerItemVideoOutput = playerItemVideoOutput;
            [currentItem addOutput:playerItemVideoOutput];
            [playerItemVideoOutput release];
        });
        
        return;
    }
    
    [asset loadTracksWithMediaCharacteristic:AVMediaCharacteristicContainsStereoMultiviewVideo completionHandler:^(NSArray<AVAssetTrack *> * _Nullable tracks, NSError * _Nullable error) {
        assert(error == nil);
        AVAssetTrack *track = tracks.firstObject;
        
        if (track == nil) {
            [asset loadTracksWithMediaType:AVMediaTypeVideo completionHandler:^(NSArray<AVAssetTrack *> * _Nullable tracks, NSError * _Nullable error) {
                assert(error == nil);
                assert(tracks != nil);
                assert(tracks.count > 0);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![self.player isEqual:player]) return;
                    if (![self.player.currentItem isEqual:currentItem]) return;
                    
                    [self _updateLayerViewCount:1];
                    [self _updateUserTransformView];
                    
                    //
                    
                    assert(self._playerVideoOutput == nil);
                    assert(self._playerItemVideoOutput == nil);
                    
                    AVPlayerItemVideoOutput *playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:nil];
#warning TODO - setup delegate
                    self._playerItemVideoOutput = playerItemVideoOutput;
                    [currentItem addOutput:playerItemVideoOutput];
                    [playerItemVideoOutput release];
                });
            }];
        } else {
            [track loadValuesAsynchronouslyForKeys:@[@"formatDescriptions"] completionHandler:^{
                float rate = player.rate;
                if (rate > 0.f) {
                    float nominalFrameRate = track.nominalFrameRate * rate;
                    CAFrameRateRange preferredFrameRateRange {
                        .maximum = nominalFrameRate,
                        .minimum = nominalFrameRate,
                        .preferred = nominalFrameRate
                    };
                    assert(CAFrameRateRangeIsValid(preferredFrameRateRange));
                    self._displayLink.preferredFrameRateRange = preferredFrameRateRange;
                }
                
                //
                
                NSArray *formatDescriptions = track.formatDescriptions;
                CMFormatDescriptionRef firstFormatDescription = (CMFormatDescriptionRef)formatDescriptions.firstObject;
                assert(firstFormatDescription != NULL);
                
                CFArrayRef tagCollections;
                assert(CMVideoFormatDescriptionCopyTagCollectionArray(firstFormatDescription, &tagCollections) == kCVReturnSuccess);
                
                std::vector<CMTagValue> videoLayerIDsVec = std::views::iota(0, CFArrayGetCount(tagCollections))
                | std::views::transform([&tagCollections](const CFIndex &index) {
                    CMTagCollectionRef tagCollection = static_cast<CMTagCollectionRef>(CFArrayGetValueAtIndex(tagCollections, index));
                    CMItemCount count = CMTagCollectionGetCount(tagCollection);
                    
                    CMTag *tags = new CMTag[count];
                    CMItemCount numberOfTagsCopied;
                    assert(CMTagCollectionGetTags(tagCollection, tags, count, &numberOfTagsCopied) == kCVReturnSuccess);
                    assert(count == numberOfTagsCopied);
                    
                    auto videoLayerIDTag = std::ranges::find_if(tags, tags + count, [](const CMTag &tag) {
                        CMTagCategory category = CMTagGetCategory(tag);
                        
                        if (category == kCMTagCategory_VideoLayerID) {
                            return true;
                        } else {
                            return false;
                        }
                    });
                    
                    std::optional<CMTagValue> videoLayerID;
                    if (videoLayerIDTag == nullptr) {
                        videoLayerID = std::nullopt;
                    } else {
                        videoLayerID = CMTagGetValue(*videoLayerIDTag);
                    }
                    
                    delete[] tags;
                    
                    return videoLayerID;
                })
                | std::views::filter([](const std::optional<CMTagValue> &opt) { return opt.has_value(); })
                | std::views::transform([](const std::optional<CMTagValue> &opt) { return opt.value(); })
                | std::ranges::to<std::vector<CMTagValue>>();
                
                CFRelease(tagCollections);
                
                size_t videoLayersCount = videoLayerIDsVec.size();
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![self.player isEqual:player]) return;
                    if (![self.player.currentItem isEqual:currentItem]) return;
                    
                    [self _updateLayerViewCount:videoLayersCount];
                    [self _updateUserTransformView];
                    
                    //
                    
                    assert(self._playerVideoOutput == nil);
                    assert(self._playerItemVideoOutput == nil);
                    
                    CMTagCollectionRef tagCollection;
                    assert(CMTagCollectionCreateWithVideoOutputPreset(kCFAllocatorDefault, kCMTagCollectionVideoOutputPreset_Stereoscopic, &tagCollection) == kCVReturnSuccess);
                    AVVideoOutputSpecification *specification = [[AVVideoOutputSpecification alloc] initWithTagCollections:@[(id)tagCollection]];
                    CFRelease(tagCollection);
                    
                    AVPlayerVideoOutput *playerVideoOutput = [[AVPlayerVideoOutput alloc] initWithSpecification:specification];
                    [specification release];
                    
                    self._playerVideoOutput = playerVideoOutput;
                    
                    assert(self.player.videoOutput == nil);
                    self.player.videoOutput = playerVideoOutput;
                    
                    [playerVideoOutput release];
                });
            }];
        }
    }];
}

- (void)_updatePreferredFrameRateRangeWithPlayer:(AVPlayer *)player {
    AVPlayerItem *currentItem = player.currentItem;
    if (currentItem == nil) return;
    
    AVAsset *asset = currentItem.asset;
    
    [asset loadTracksWithMediaCharacteristic:AVMediaCharacteristicContainsStereoMultiviewVideo completionHandler:^(NSArray<AVAssetTrack *> * _Nullable tracks, NSError * _Nullable error) {
        assert(error == nil);
        AVAssetTrack *track = tracks.firstObject;
        
        if (track == nil) {
            [asset loadTracksWithMediaType:AVMediaTypeVideo completionHandler:^(NSArray<AVAssetTrack *> * _Nullable tracks, NSError * _Nullable error) {
                assert(error == nil);
                assert(tracks != nil);
                AVAssetTrack *track = tracks.firstObject;
                assert(track != nil);
                
                [track loadValuesAsynchronouslyForKeys:@[@"nominalFrameRate"] completionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (![self.player isEqual:player]) return;
                        if (![self.player.currentItem isEqual:currentItem]) return;
                        [self _updatePreferredFrameRateRangeWithPlayer:player nominalFrameRate:track.nominalFrameRate];
                    });
                }];
            }];
        } else {
            [track loadValuesAsynchronouslyForKeys:@[@"nominalFrameRate"] completionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![self.player isEqual:player]) return;
                    if (![self.player.currentItem isEqual:currentItem]) return;
                    [self _updatePreferredFrameRateRangeWithPlayer:player nominalFrameRate:track.nominalFrameRate];
                });
            }];
        }
    }];
}

- (void)_updatePreferredFrameRateRangeWithPlayer:(AVPlayer *)player nominalFrameRate:(float)nominalFrameRate {
    float rate = player.rate;
    
    if (rate > 0.f) {
        float frameRate = nominalFrameRate * rate;
        CAFrameRateRange preferredFrameRateRange {
            .maximum = frameRate,
            .minimum = frameRate,
            .preferred = frameRate
        };
        assert(CAFrameRateRangeIsValid(preferredFrameRateRange));
        self._displayLink.preferredFrameRateRange = preferredFrameRateRange;
    }
}

- (void)_updateUserTransformView {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    AVPlayerItem *currentItem = self.player.currentItem;
    if (currentItem == nil) return;
    
    NSUInteger viewCount = self._stackView.arrangedSubviews.count;
    if (viewCount == 0) return;
    
    CGSize size = currentItem.presentationSize;
    size.width *= viewCount;
    
    CGRect rect = AVMakeRectWithAspectRatioInsideRect(size, self._userTransformView.frame);
    self._userTransformView.contentPixelSize = rect.size;
    self._userTransformView.untransformedContentFrame = rect;
}

- (void)userTransformView:(UserTransformView *)userTransformView didChangeUserAffineTransform:(CGAffineTransform)userAffineTransform isUserInteracting:(BOOL)isUserInteracting {
//    NSLog(@"%@", NSStringFromCGAffineTransform(userAffineTransform));
    self._stackView.transform = userAffineTransform;
}

@end
