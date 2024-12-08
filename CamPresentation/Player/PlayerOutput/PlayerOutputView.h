//
//  PlayerOutputView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/8/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerOutputView : UIView
@property (retain, nonatomic, nullable) AVPlayer *player;
@end

NS_ASSUME_NONNULL_END
