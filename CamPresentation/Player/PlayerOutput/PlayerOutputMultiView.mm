//
//  PlayerOutputMultiView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/1/24.
//

#import <CamPresentation/PlayerOutputMultiView.h>
#import <CamPresentation/PixelBufferLayerView.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <objc/message.h>
#import <objc/runtime.h>
#include <algorithm>
#include <vector>
#include <ranges>
#include <optional>

#warning TODO : Leak

CA_EXTERN_C_BEGIN
BOOL CAFrameRateRangeIsValid(CAFrameRateRange range);
CA_EXTERN_C_END

@interface PlayerOutputMultiView ()
@property (retain, nonatomic, nullable) AVPlayer * _player;
@property (retain, atomic, nullable) AVPlayerVideoOutput *_videoOutput; // SVRunLoop와 Main Thread에서 접근되므로 atomic
@property (copy, atomic, nullable) NSArray<PixelBufferLayer *> *_pixelBufferLayers;
@property (retain, nonatomic, readonly) SVRunLoop *_renderRunLoop;
@property (retain, nonatomic, readonly) CADisplayLink *_displayLink;
@property (retain, nonatomic, readonly) UIStackView *_stackView;
@end

@implementation PlayerOutputMultiView
@synthesize _renderRunLoop = __renderRunLoop;
@synthesize _displayLink = __displayLink;
@synthesize _stackView = __stackView;

+ (Class)layerClass {
    return [PixelBufferLayer class];
}

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
    if (AVPlayer *player = __player) {
        [self _removeObserversForPlayer:player];
        [player release];
    }
    [__videoOutput release];
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
            [self _didChangeCurrentItemForPlayer:player];
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

- (void)updateWithPlayer:(AVPlayer *)player specification:(AVVideoOutputSpecification *)specification {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (AVPlayer *oldPlayer = self._player) {
        assert(oldPlayer.videoOutput != nil);
        assert([oldPlayer.videoOutput isEqual:self._videoOutput]);
        oldPlayer.videoOutput = nil;
        [self _removeObserversForPlayer:oldPlayer];
        self._displayLink.paused = YES;
    }
    
    if (player == nil) {
        [self _updatePixelBufferLayerViewCount:0];
        return;
    }
    
    self._player = player;
    [self _addObserversForPlayer:player];
    
    AVPlayerVideoOutput *videoOutput = [[AVPlayerVideoOutput alloc] initWithSpecification:specification];
    assert(player.videoOutput == nil);
    player.videoOutput = videoOutput;
    self._videoOutput = videoOutput;
    assert([player.videoOutput isEqual:videoOutput]);
    [videoOutput release];
}

- (SVRunLoop *)_renderRunLoop {
    if (auto renderRunLoop = __renderRunLoop) return renderRunLoop;
    
    SVRunLoop *renderRunLoop = [[SVRunLoop alloc] initWithThreadName:@"PlayerOutView Render Thread"];
    
    __renderRunLoop = [renderRunLoop retain];
    return [renderRunLoop autorelease];
}

- (CADisplayLink *)_displayLink {
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
    CMTime hostTime = CMTimeMake(static_cast<int64_t>(sender.timestamp * USEC_PER_SEC), USEC_PER_SEC);
    
    CMTime presentationTimeStamp;
    AVPlayerVideoOutputConfiguration *activeConfiguration;
    CMTaggedBufferGroupRef _Nullable taggedBufferGroup = [self._videoOutput copyTaggedBufferGroupForHostTime:hostTime presentationTimeStamp:&presentationTimeStamp activeConfiguration:&activeConfiguration];
    
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
}

- (void)_didChangeRateForPlayer:(AVPlayer *)player {
    dispatch_async(dispatch_get_main_queue(), ^{
        assert([self._player isEqual:player]);
        float rate = player.rate;
        self._displayLink.paused = (rate == 0.f);
    });
    
    [self _updatePreferredFrameRateRangeWithPlayer:player];
}

- (void)_didChangeCurrentItemForPlayer:(AVPlayer *)player {
    AVPlayerItem * _Nullable currentItem = player.currentItem;
    if (currentItem == nil) return;
    
    [self _updatePreferredFrameRateRangeWithPlayer:player];
    
    AVAsset *asset = currentItem.asset;
    
    [asset loadTracksWithMediaCharacteristic:AVMediaCharacteristicContainsStereoMultiviewVideo completionHandler:^(NSArray<AVAssetTrack *> * _Nullable tracks, NSError * _Nullable error) {
        assert(error == nil);
        AVAssetTrack *track = tracks.firstObject;
        if (track == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self._player.currentItem isEqual:currentItem]) return;
                [self _updatePixelBufferLayerViewCount:0];
            });
        }
        
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
                if (![self._player.currentItem isEqual:currentItem]) return;
                [self _updatePixelBufferLayerViewCount:videoLayersCount];
            });
        }];
    }];
}

- (void)_updatePreferredFrameRateRangeWithPlayer:(AVPlayer *)player {
    AVPlayerItem *currentItem = player.currentItem;
    if (currentItem == nil) return;
    
    AVAsset *asset = currentItem.asset;
    
    [asset loadTracksWithMediaCharacteristic:AVMediaCharacteristicContainsStereoMultiviewVideo completionHandler:^(NSArray<AVAssetTrack *> * _Nullable tracks, NSError * _Nullable error) {
        assert(error == nil);
        AVAssetTrack *track = tracks.firstObject;
        if (track == nil) return;
        
        [track loadValuesAsynchronouslyForKeys:@[@"nominalFrameRate"] completionHandler:^{
            [self _updatePreferredFrameRateRangeWithPlayer:player nominalFrameRate:track.nominalFrameRate];
        }];
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
