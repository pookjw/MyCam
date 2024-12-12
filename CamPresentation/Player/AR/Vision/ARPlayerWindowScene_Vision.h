//
//  ARPlayerWindowScene_Vision.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/11/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(visionos(1.0))
@interface ARPlayerWindowScene_Vision : UIWindowScene
@property (retain, nonatomic, nullable) AVPlayer *player;
@property (retain, nonatomic, nullable) AVSampleBufferVideoRenderer *videoRenderer;
@end

NS_ASSUME_NONNULL_END
