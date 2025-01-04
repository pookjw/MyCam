//
//  AVPlayerItemVideoOutput+Category.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/4/25.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayerItemVideoOutput (Category)
@property (nonatomic, readonly, nullable) AVPlayerItem *cp_playerItem;
@end

NS_ASSUME_NONNULL_END
