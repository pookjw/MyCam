//
//  CinematicEditTimelineDetectionsThumbnailView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicEditTimelineDetectionsThumbnailView.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <CamPresentation/CinematicEditTimelineCollectionViewLayoutAttributes.h>
#import <CamPresentation/PlayerLayerView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/CinematicEditTimelineDetectionThumbnailVideoCompositor.h>
#import <CamPresentation/CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction.h>

__attribute__((objc_direct_members))
@interface CinematicEditTimelineDetectionsThumbnailView ()
@property (retain, nonatomic, readonly, getter=_playerLayerView) PlayerLayerView *playerLayerView;
@property (retain, nonatomic, readonly, getter=_player) AVPlayer *player;
@property (retain, nonatomic, nullable, getter=_snapshot, setter=_setSnapshot:) CinematicSnapshot *snapshot;
@end

@implementation CinematicEditTimelineDetectionsThumbnailView
@synthesize playerLayerView = _playerLayerView;
@synthesize player = _player;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.userInteractionEnabled = NO;
        
        PlayerLayerView *playerLayerView = self.playerLayerView;
        [self addSubview:playerLayerView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), playerLayerView);
    }
    
    return self;
}

- (void)dealloc {
    [_playerLayerView release];
    [_player release];
    [_snapshot release];
    [super dealloc];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [super applyLayoutAttributes:layoutAttributes];
    [self _updatePlayer];
}

- (void)updateWithSnapshot:(CinematicSnapshot *)snapshot {
    self.snapshot = snapshot;
    [self _updatePlayer];
}

- (PlayerLayerView *)_playerLayerView {
    if (auto playerLayerView = _playerLayerView) return playerLayerView;
    
    PlayerLayerView *playerLayerView = [PlayerLayerView new];
    AVPlayerLayer *playerLayer = playerLayerView.playerLayer;
    playerLayer.player = self.player;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    _playerLayerView = playerLayerView;
    return playerLayerView;
}

- (AVPlayer *)_player {
    if (auto player = _player) return player;
    
    AVPlayer *player = [AVPlayer new];
    
    _player = player;
    return player;
}

- (void)_updatePlayer __attribute__((objc_direct)) {
    CinematicSnapshot *snapshot = self.snapshot;
    if (snapshot == nil) return;
    
    CNScript *script = snapshot.assetData.cnScript;
    CNCompositionInfo *compositionInfo = snapshot.compositionInfo;
    AVAsset *asset = snapshot.assetData.avAsset;
    
    UICollectionViewLayoutAttributes *_layoutAttributes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_layoutAttributes"));
    if (_layoutAttributes == nil) return;
    assert([_layoutAttributes isKindOfClass:[CinematicEditTimelineCollectionViewLayoutAttributes class]]);
    
    auto casted = static_cast<CinematicEditTimelineCollectionViewLayoutAttributes *>(_layoutAttributes);
    assert(casted.thumbnailPresentationTrackID != kCMPersistentTrackID_Invalid);
    assert(CMTIME_IS_VALID(casted.thumbnailPresentationTime));
    assert([CNDetection isValidDetectionID:casted.thumbnailPresentationTrackID]);
    
    CNDetectionTrack *detectionTrack = [script detectionTrackForID:casted.thumbnailPresentationDetectionTrackID];
    assert(detectionTrack != nil);
    
    CNDetection *detection = [detectionTrack detectionNearestTime:casted.thumbnailPresentationTime];
    assert(detection != nil);
    
    AVPlayer *player = self.player;
    
    if (AVPlayerItem *oldPlayerItem = player.currentItem) {
        [oldPlayerItem cancelPendingSeeks];
    }
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    
    //
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition new];
    videoComposition.sourceTrackIDForFrameTiming = compositionInfo.frameTimingTrack.trackID;
    videoComposition.sourceSampleDataTrackIDs = compositionInfo.sampleDataTrackIDs;
    videoComposition.customVideoCompositorClass = [CinematicEditTimelineDetectionThumbnailVideoCompositor class];
    videoComposition.renderSize = snapshot.assetData.cnAssetInfo.preferredSize;
    
    CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction *instruction = [[CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction alloc] initWithSnapshot:snapshot detection:detection];
    
    videoComposition.instructions = @[instruction];
    [instruction release];
    
    if (snapshot.assetData.nominalFrameRate <= 0.f) {
        videoComposition.frameDuration = CMTimeMake(1, 30);
    } else {
        videoComposition.frameDuration = CMTimeMakeWithSeconds(1.f / snapshot.assetData.nominalFrameRate, snapshot.assetData.naturalTimeScale);
    }
    
    playerItem.videoComposition = videoComposition;
    [videoComposition release];
    
    //
    
    [player replaceCurrentItemWithPlayerItem:playerItem];
    [playerItem release];
    
    BOOL found = NO;
    for (AVPlayerItemTrack *track in playerItem.tracks) {
        if (track.assetTrack.trackID == casted.thumbnailPresentationTrackID) {
            track.enabled = YES;
            found = YES;
        } else {
            track.enabled = NO;
        }
    }
    assert(found);
    
    [player seekToTime:casted.thumbnailPresentationTime toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
    }];
}

@end

#endif
