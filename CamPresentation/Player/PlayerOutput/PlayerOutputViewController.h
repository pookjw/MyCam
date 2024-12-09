//
//  PlayerOutputViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/29/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/PlayerOutputLayerType.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerOutputViewController : UIViewController
@property (retain, nonatomic, nullable) AVPlayer *player;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithLayerType:(PlayerOutputLayerType)layerType;
@end

NS_ASSUME_NONNULL_END
