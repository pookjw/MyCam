//
//  PlayerOutputView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/8/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/PlayerOutputLayerType.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerOutputView : UIView
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame layerType:(PlayerOutputLayerType)layerType;
@property (retain, nonatomic, nullable) AVPlayer *player;
@end

NS_ASSUME_NONNULL_END
