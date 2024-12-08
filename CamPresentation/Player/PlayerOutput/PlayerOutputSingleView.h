//
//  PlayerOutputSingleView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/3/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerOutputSingleView : UIView
@property (retain, nonatomic, nullable) AVPlayer *player;
@end

NS_ASSUME_NONNULL_END
