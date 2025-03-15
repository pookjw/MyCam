//
//  CinematicEditTimelineDisparityThumbnailView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicEditTimelineDisparityThumbnailView.h>
#import <CamPresentation/CinematicEditTimelineCollectionViewLayoutAttributes.h>
#import <CamPresentation/PlayerLayerView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction.h>
#import <CamPresentation/CinematicEditTimelineDisparityThumbnailVideoCompositor.h>

__attribute__((objc_direct_members))
@interface CinematicEditTimelineDisparityThumbnailView ()
@property (retain, nonatomic, readonly, getter=_playerLayerView) PlayerLayerView *playerLayerView;
@property (retain, nonatomic, readonly, getter=_player) AVPlayer *player;
@property (retain, nonatomic, nullable, getter=_snapshot, setter=_setSnapshot:) CinematicSnapshot *snapshot;
@end

@implementation CinematicEditTimelineDisparityThumbnailView
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
    
    AVPlayer *player = self.player;
    
    if (AVPlayerItem *oldPlayerItem = player.currentItem) {
        [oldPlayerItem cancelPendingSeeks];
    }
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    
    //
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition new];
    videoComposition.sourceTrackIDForFrameTiming = compositionInfo.frameTimingTrack.trackID;
    videoComposition.sourceSampleDataTrackIDs = compositionInfo.sampleDataTrackIDs;
    videoComposition.customVideoCompositorClass = [CinematicEditTimelineDisparityThumbnailVideoCompositor class];
    videoComposition.renderSize = snapshot.assetData.cnAssetInfo.preferredSize;
    
    CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction *instruction = [[CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction alloc] initWithSnapshot:snapshot];
    
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
    
    [player seekToTime:casted.thumbnailPresentationTime toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
    }];
}

@end
