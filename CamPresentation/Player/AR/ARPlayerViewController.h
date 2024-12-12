//
//  ARPlayerViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/18/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(tvos)
@interface ARPlayerViewController : UIViewController
@property (retain, nonatomic, nullable) AVPlayer *player;
@end

NS_ASSUME_NONNULL_END
