//
//  CinematicEditTimelineDetectionThumbnailView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicEditTimelineDetectionThumbnailView.h>
#import <CamPresentation/CinematicEditTimelineCollectionViewLayoutAttributes.h>
#import <CamPresentation/PlayerLayerView.h>
#import <objc/message.h>
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface CinematicEditTimelineDetectionThumbnailView ()
@property (retain, nonatomic, readonly, getter=_playerLayerView) PlayerLayerView *playerLayerView;
@property (retain, nonatomic, readonly, getter=_player) AVPlayer *player;
@property (retain, nonatomic, nullable, getter=_script, setter=_setScript:) CNScript *script;
@property (copy, nonatomic, nullable, getter=_asset, setter=_setAsset:) AVAsset *asset;
@end

@implementation CinematicEditTimelineDetectionThumbnailView
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
    [_script release];
    [_asset release];
    [super dealloc];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [super applyLayoutAttributes:layoutAttributes];
    [self _updatePlayer];
}

- (void)updateWithScript:(CNScript *)script asset:(AVAsset *)asset {
    self.script = script;
    self.asset = asset;
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
    CNScript *script = self.script;
    if (script == nil) return;
    
    AVAsset *asset = self.asset;
    if (asset == nil) return;
    
    UICollectionViewLayoutAttributes *_layoutAttributes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_layoutAttributes"));
    if (_layoutAttributes == nil) return;
    assert([_layoutAttributes isKindOfClass:[CinematicEditTimelineCollectionViewLayoutAttributes class]]);
    
    auto casted = static_cast<CinematicEditTimelineCollectionViewLayoutAttributes *>(_layoutAttributes);
    assert(casted.thumbnailPresentationTrackID != kCMPersistentTrackID_Invalid);
    assert(CMTIME_IS_VALID(casted.thumbnailPresentationTime));
    assert([CNDetection isValidDetectionID:casted.thumbnailPresentationTrackID]);
    
    AVPlayer *player = self.player;
    AVPlayerItem *currentItem = player.currentItem;
    if (currentItem == nil) return;
    [currentItem cancelPendingSeeks];
    
    BOOL found = NO;
    for (AVPlayerItemTrack *track in currentItem.tracks) {
        if (track.assetTrack.trackID == casted.thumbnailPresentationTrackID) {
            track.enabled = YES;
            found = YES;
        } else {
            track.enabled = NO;
        }
    }
    assert(found);
    
    [player seekToTime:casted.thumbnailPresentationTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
    }];
}

@end
