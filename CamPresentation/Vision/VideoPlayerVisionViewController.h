//
//  VideoPlayerVisionViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/5/25.
//

#import <CamPresentation/ImageVisionViewController.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayerVisionViewController : ImageVisionViewController
@property (retain, nonatomic, nullable) AVPlayer *player;
@end

NS_ASSUME_NONNULL_END
