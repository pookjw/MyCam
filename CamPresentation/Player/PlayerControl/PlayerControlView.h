//
//  PlayerControlView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/29/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerControlView : UIView
@property (retain, nonatomic, nullable) AVPlayer *player;
@end

NS_ASSUME_NONNULL_END
