//
//  VideoPlayerListViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/28/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayerListViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout NS_UNAVAILABLE;
- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem;
- (instancetype)initWithAsset:(PHAsset *)asset;
@end

NS_ASSUME_NONNULL_END
