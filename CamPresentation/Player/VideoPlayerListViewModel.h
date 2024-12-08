//
//  VideoPlayerListViewModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/28/24.
//

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayerListViewModel : NSObject
@property (retain, nonatomic, readonly, nullable) AVPlayer *player;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem;
- (instancetype)initWithAsset:(PHAsset *)asset;
- (instancetype)initWithPlayer:(AVPlayer *)player;
- (void)cancelLoading;
- (void)loadPlayerWithProgressHandler:(PHAssetVideoProgressHandler)progressHandler comletionHandler:(void (^ _Nullable)(void))completionHandler;
@end

NS_ASSUME_NONNULL_END
