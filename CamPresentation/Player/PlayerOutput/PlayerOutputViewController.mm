//
//  PlayerOutputViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/29/24.
//

#import <CamPresentation/PlayerOutputViewController.h>
#import <CamPresentation/PlayerOutputSingleView.h>
#import <CamPresentation/PlayerOutputMultiView.h>
#import <CamPresentation/PlayerControlView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

typedef NS_ENUM(NSUInteger, PlayerOutputViewType) {
    PlayerOutputViewTypeNone,
    PlayerOutputViewTypeSingle,
    PlayerOutputViewTypeMulti
};

@interface PlayerOutputViewController ()
@property (retain, nonatomic, nullable) PlayerOutputSingleView *_outputSingleView;
@property (retain, nonatomic, nullable) PlayerOutputMultiView *_outputMultiView;
@property (retain, nonatomic, readonly) PlayerControlView *_controlView;
@end

@implementation PlayerOutputViewController
@synthesize player = _player;
@synthesize _outputSingleView = __outputSingleView;
@synthesize _outputMultiView = __outputMultiView;
@synthesize _controlView = __controlView;

- (void)dealloc {
    if (AVPlayer *player = _player) {
        [self _removeObserversForPlayer:player];
        [player release];
    }
    [__outputSingleView release];
    [__outputMultiView release];
    [__controlView release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[AVPlayer class]]) {
        auto player = static_cast<AVPlayer *>(object);
        
        if ([keyPath isEqualToString:@"currentItem"]) {
            [self _didChangeCurrentItemForPlayer:player];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if !TARGET_OS_TV
    self.view.backgroundColor = UIColor.systemBackgroundColor;
#endif
    
    PlayerControlView *controlView = self._controlView;
    controlView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:controlView];
    
    [NSLayoutConstraint activateConstraints:@[
        [controlView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
        [controlView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [controlView.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor]
    ]];
}

- (void)setPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (AVPlayer *oldPlayer = _player) {
        [self _removeObserversForPlayer:oldPlayer];
        [oldPlayer release];
    }
    
    if (player == nil) {
        _player = nil;
        return;
    }
    
    _player = [player retain];
    [self _addObserversForPlayer:player];
    self._controlView.player = player;
}

- (void)_removeObserversForPlayer:(AVPlayer *)player {
    assert(player != nil);
    [player removeObserver:self forKeyPath:@"currentItem"];
}

- (void)_addObserversForPlayer:(AVPlayer *)player {
    assert(player != nil);
    [player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

- (void)_didChangeCurrentItemForPlayer:(AVPlayer *)player {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self.player isEqual:player]) {
            return;
        }
        
        AVPlayerItem * _Nullable currentItem = player.currentItem;
        
        //
        
        if (currentItem == nil) {
            [self _configureOutputViewWithType:PlayerOutputViewTypeNone];
            return;
        }
        
        //
        
        AVAsset *asset = currentItem.asset;
        
        [asset loadTracksWithMediaCharacteristic:AVMediaCharacteristicContainsStereoMultiviewVideo completionHandler:^(NSArray<AVAssetTrack *> * _Nullable tracks, NSError * _Nullable error) {
            assert(error == nil);
            assert(tracks != nil);
            
            if (tracks.count > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.player isEqual:player] and [self.player.currentItem isEqual:currentItem]) {
                        [self _configureOutputViewWithType:PlayerOutputViewTypeMulti];
                    }
                });
                return;
            }
            
            [asset loadTracksWithMediaType:AVMediaTypeVideo completionHandler:^(NSArray<AVAssetTrack *> * _Nullable tracks, NSError * _Nullable error) {
                assert(error == nil);
                assert(tracks != nil);
                assert(tracks.count > 0);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.player isEqual:player] and [self.player.currentItem isEqual:currentItem]) {
                        [self _configureOutputViewWithType:PlayerOutputViewTypeSingle];
                    }
                });
                return;
            }];
        }];
    });
}

- (void)_configureOutputViewWithType:(PlayerOutputViewType)type {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    switch (type) {
        case PlayerOutputViewTypeNone: {
            if (PlayerOutputSingleView *outputSingleView = self._outputSingleView) {
                [outputSingleView removeFromSuperview];
                self._outputSingleView = nil;
            }
            
            if (PlayerOutputMultiView *outputMultiView = self._outputMultiView) {
                [outputMultiView updateWithPlayer:nil specification:nil];
                [outputMultiView removeFromSuperview];
                self._outputMultiView = nil;
            }
            break;
        }
        case PlayerOutputViewTypeSingle: {
            if (self._outputSingleView == nil) {
                PlayerOutputSingleView *outputSingleView = [PlayerOutputSingleView new];
                self._outputSingleView = outputSingleView;
                
                [self.view addSubview:outputSingleView];
                outputSingleView.translatesAutoresizingMaskIntoConstraints = NO;
                [NSLayoutConstraint activateConstraints:@[
                    [outputSingleView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
                    [outputSingleView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
                    [outputSingleView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
                    [outputSingleView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
                ]];
                
                outputSingleView.player = self.player;
                [outputSingleView release];
                
                [self.view bringSubviewToFront:self._controlView];
            }
            
            if (PlayerOutputMultiView *outputMultiView = self._outputMultiView) {
                [outputMultiView updateWithPlayer:nil specification:nil];
                [outputMultiView removeFromSuperview];
                self._outputMultiView = nil;
            }
            
            break;
        }
        case PlayerOutputViewTypeMulti: {
            if (PlayerOutputSingleView *outputSingleView = self._outputSingleView) {
                [outputSingleView removeFromSuperview];
                self._outputSingleView = nil;
            }
            
            if (self._outputMultiView == nil) {
                CMTagCollectionRef tagCollection;
                assert(CMTagCollectionCreateWithVideoOutputPreset(kCFAllocatorDefault, kCMTagCollectionVideoOutputPreset_Stereoscopic, &tagCollection) == 0);
                AVVideoOutputSpecification *specification = [[AVVideoOutputSpecification alloc] initWithTagCollections:@[(id)tagCollection]];
                CFRelease(tagCollection);
                
                PlayerOutputMultiView *outputMultiView = [PlayerOutputMultiView new];
                self._outputMultiView = outputMultiView;
                
                [self.view addSubview:outputMultiView];
                outputMultiView.translatesAutoresizingMaskIntoConstraints = NO;
                [NSLayoutConstraint activateConstraints:@[
                    [outputMultiView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
                    [outputMultiView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
                    [outputMultiView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
                    [outputMultiView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
                ]];
                
                [outputMultiView updateWithPlayer:self.player specification:specification];
                [specification release];
                
                [outputMultiView release];
                
                [self.view bringSubviewToFront:self._controlView];
            }
            
            break;
        }
        default:
            abort();
    }
}

- (PlayerControlView *)_controlView {
    if (auto controlView = __controlView) return controlView;
    
    PlayerControlView *controlView = [PlayerControlView new];
    
    __controlView = [controlView retain];
    return [controlView autorelease];
}

@end
