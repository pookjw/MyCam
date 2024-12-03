//
//  AVPlayerVideoOutput+Category.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/3/24.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayerVideoOutput (Category)
@property (class, nonatomic, readonly) BOOL cp_isSupported;
@end

NS_ASSUME_NONNULL_END
