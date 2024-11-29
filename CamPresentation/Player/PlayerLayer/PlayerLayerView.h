//
//  PlayerLayerView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/9/24.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerLayerView : UIView
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;
@end

NS_ASSUME_NONNULL_END
