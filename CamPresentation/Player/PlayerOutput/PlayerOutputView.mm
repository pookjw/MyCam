//
//  PlayerOutputView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/8/24.
//

#import <CamPresentation/PlayerOutputView.h>
#import <CamPresentation/PixelBufferLayerView.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <objc/message.h>
#import <objc/runtime.h>
#include <algorithm>
#include <vector>
#include <ranges>
#include <optional>

#warning TODO Memory Leak, PixelBufferAttributes 해상도 조정, AVPlayerItem 및 Output쪽 더 보기, 첫 프레임 가져오기

CA_EXTERN_C_BEGIN
BOOL CAFrameRateRangeIsValid(CAFrameRateRange range);
CA_EXTERN_C_END

@interface PlayerOutputView ()
@property (retain, atomic, nullable) AVPlayerVideoOutput *_playerVideoOutput; // SVRunLoop와 Main Thread에서 접근되므로 atomic
@property (retain, atomic, nullable) AVPlayerItemVideoOutput *_playerItemVideoOutput; // SVRunLoop와 Main Thread에서 접근되므로 atomic
@property (copy, atomic, nullable) NSArray<PixelBufferLayer *> *_pixelBufferLayers;
@property (retain, nonatomic, readonly) SVRunLoop *_renderRunLoop;
@property (retain, nonatomic, readonly) CADisplayLink *_displayLink;
@property (retain, nonatomic, readonly) UIStackView *_stackView;
@end

@implementation PlayerOutputView
@synthesize _renderRunLoop = __renderRunLoop;
@synthesize _displayLink = __displayLink;
@synthesize _stackView = __stackView;

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self _commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _commonInit];
    }
    
    return self;
}

- (void)dealloc {
    if (AVPlayer *player = _player) {
        [self _removeObserversForPlayer:player];
        player.videoOutput = nil;
        
        if (AVPlayerItemVideoOutput *playerItemVideoOutput = __playerItemVideoOutput) {
            [player.currentItem removeOutput:playerItemVideoOutput];
        }
        
        [player release];
    }
    [__playerVideoOutput release];
    [__playerItemVideoOutput release];
    [__pixelBufferLayers release];
    [__renderRunLoop release];
    __displayLink.paused = YES;
    [__displayLink release];
    [__stackView release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[AVPlayer class]]) {
        auto player = static_cast<AVPlayer *>(object);
        
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

- (void)_commonInit {
    UIStackView *stackView = self._stackView;
    [self addSubview:stackView];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), stackView);
}

- (void)setPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (AVPlayer *oldPlayer = self.player) {
        assert(oldPlayer.videoOutput != nil);
        assert([oldPlayer.videoOutput isEqual:self._playerVideoOutput]);
        oldPlayer.videoOutput = nil;
        [self _removeObserversForPlayer:oldPlayer];
        self._displayLink.paused = YES;
        [oldPlayer release];
    }
    
    if (player == nil) {
        _player = nil;
        [self _updatePixelBufferLayerViewCount:0];
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

- (CADisplayLink *)_displayLink {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (auto displayLink = __displayLink) return displayLink;
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_didTriggerDisplayLink:)];
    
    displayLink.paused = YES;
    [self._renderRunLoop runBlock:^{
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }];
    //    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    __displayLink = [displayLink retain];
    return displayLink;
}

- (UIStackView *)_stackView {
    if (auto stackView = __stackView) return stackView;
    
    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    
    __stackView = [stackView retain];
    return [stackView autorelease];
}

- (void)_updatePixelBufferLayerViewCount:(NSUInteger)count {
    UIStackView *stackView = self._stackView;
    NSUInteger currentCount = stackView.arrangedSubviews.count;
    
    if (currentCount == count) {
        return;
    } else if (currentCount < count) {
        NSUInteger newCount = count - currentCount;
        
        for (NSUInteger i = 0; i < newCount; i++) {
            PixelBufferLayerView *pixelBufferLayerView = [PixelBufferLayerView new];
            [stackView addArrangedSubview:pixelBufferLayerView];
            [pixelBufferLayerView release];
        }
        
        [stackView updateConstraintsIfNeeded];
    } else if (count < currentCount) {
        NSUInteger deletedCount = currentCount - count;
        
        for (NSUInteger i = 0; i < deletedCount; i++) {
            auto pixelBufferLayerView = static_cast<PixelBufferLayerView *>(stackView.arrangedSubviews.lastObject);
            assert(pixelBufferLayerView != nil);
            [stackView removeArrangedSubview:pixelBufferLayerView];
        }
        
        [stackView updateConstraintsIfNeeded];
    }
    
    NSMutableArray<PixelBufferLayer *> *pixelBufferLayers = [[NSMutableArray alloc] initWithCapacity:count];
    for (PixelBufferLayerView *pixelBufferLayerView in stackView.arrangedSubviews) {
        [pixelBufferLayers addObject:pixelBufferLayerView.pixelBufferLayer];
    }
    self._pixelBufferLayers = pixelBufferLayers;
    [pixelBufferLayers release];
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
        
        for (CFIndex index : std::views::iota(0, CMTaggedBufferGroupGetCount(taggedBufferGroup))) {
            CMTagCollectionRef tagCollection = CMTaggedBufferGroupGetTagCollectionAtIndex(taggedBufferGroup, index);
            
            CMItemCount tagCollectionCount = CMTagCollectionGetCount(tagCollection);
            
            CMTag *tags = new CMTag[tagCollectionCount];
            CMItemCount numberOfTagsCopied;
            assert(CMTagCollectionGetTags(tagCollection, tags, tagCollectionCount, &numberOfTagsCopied) == 0);
            assert(tagCollectionCount == numberOfTagsCopied);
            
            for (const CMTag *tagPtr : std::views::iota(tags, tags + numberOfTagsCopied)) {
                CMTag tag = *tagPtr;
                CMTagCategory category = CMTagGetCategory(tag);
                if (category != kCMTagCategory_StereoView) continue;
                
                CMTagValue value = CMTagGetValue(tag);
                CVPixelBufferRef _Nullable pixelBuffer = CMTaggedBufferGroupGetCVPixelBufferAtIndex(taggedBufferGroup, index);
                if (pixelBuffer == nil) break;
                
                NSInteger index;
                if (value == kCMStereoView_LeftEye) {
                    index = 0;
                } else if (value == kCMStereoView_RightEye) {
                    index = 1;
                } else {
                    abort();
                }
                
                NSArray<PixelBufferLayer *> *pixelBufferLayers = self._pixelBufferLayers;
                if (pixelBufferLayers.count <= index) break;
                
                PixelBufferLayer * pixelBufferLayer = pixelBufferLayers[index];
                [pixelBufferLayer updateWithPixelBuffer:pixelBuffer];
            }
            
            delete[] tags;
        }
        
        CFRelease(taggedBufferGroup);
    } else if (AVPlayerItemVideoOutput *playerItemVideoOutput = self._playerItemVideoOutput) {
        id _videoOutputInternal;
        assert(object_getInstanceVariable(playerItemVideoOutput, "_videoOutputInternal", reinterpret_cast<void **>(&_videoOutputInternal)));
        id playerItemWeakReference;
        assert(object_getInstanceVariable(_videoOutputInternal, "playerItemWeakReference", reinterpret_cast<void **>(&playerItemWeakReference)));
        AVPlayerItem *playerItem = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(playerItemWeakReference, sel_registerName("referencedObject"));
        if (playerItem == nil) return;
        
        CMTime currentTime = playerItem.currentTime;
        
        if (![playerItemVideoOutput hasNewPixelBufferForItemTime:currentTime]) {
            return;
        }
        
        NSArray<PixelBufferLayer *> *pixelBufferLayers = self._pixelBufferLayers;
        PixelBufferLayer *pixelBufferLayer = pixelBufferLayers.firstObject;
        if (pixelBufferLayer == nil) return;
        
        CMTime displayItem;
        CVPixelBufferRef _Nullable pixelBuffer = [playerItemVideoOutput copyPixelBufferForItemTime:currentTime itemTimeForDisplay:&displayItem];
        
        if (pixelBuffer) {
            [pixelBufferLayer updateWithPixelBuffer:pixelBuffer];
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
                    
                    [self _updatePixelBufferLayerViewCount:1];
                    
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
                assert(CMVideoFormatDescriptionCopyTagCollectionArray(firstFormatDescription, &tagCollections) == 0);
                
                std::vector<CMTagValue> videoLayerIDsVec = std::views::iota(0, CFArrayGetCount(tagCollections))
                | std::views::transform([&tagCollections](const CFIndex &index) {
                    CMTagCollectionRef tagCollection = static_cast<CMTagCollectionRef>(CFArrayGetValueAtIndex(tagCollections, index));
                    CMItemCount count = CMTagCollectionGetCount(tagCollection);
                    
                    CMTag *tags = new CMTag[count];
                    CMItemCount numberOfTagsCopied;
                    assert(CMTagCollectionGetTags(tagCollection, tags, count, &numberOfTagsCopied) == 0);
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
                    
                    [self _updatePixelBufferLayerViewCount:videoLayersCount];
                    
                    //
                    
                    assert(self._playerVideoOutput == nil);
                    assert(self._playerItemVideoOutput == nil);
                    
                    CMTagCollectionRef tagCollection;
                    assert(CMTagCollectionCreateWithVideoOutputPreset(kCFAllocatorDefault, kCMTagCollectionVideoOutputPreset_Stereoscopic, &tagCollection) == 0);
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
                        NSLog(@"%lf", track.nominalFrameRate);
                        [self _updatePreferredFrameRateRangeWithPlayer:player nominalFrameRate:track.nominalFrameRate];
                    });
                }];
            }];
        } else {
            [track loadValuesAsynchronouslyForKeys:@[@"nominalFrameRate"] completionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![self.player isEqual:player]) return;
                    if (![self.player.currentItem isEqual:currentItem]) return;
                    NSLog(@"%lf", track.nominalFrameRate);
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

@end
