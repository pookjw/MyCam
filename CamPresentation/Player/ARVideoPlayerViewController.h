//
//  ARVideoPlayerViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/18/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARVideoPlayerViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithAsset:(PHAsset *)asset;
- (instancetype)initWithPlayer:(AVPlayer *)player;
- (instancetype)initWithVideoRenderer:(AVSampleBufferVideoRenderer *)videoRenderer;
@end

NS_ASSUME_NONNULL_END
