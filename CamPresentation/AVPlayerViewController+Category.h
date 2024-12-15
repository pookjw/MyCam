//
//  AVPlayerViewController+Category.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/15/24.
//

#import <AVKit/AVKit.h>
#include <optional>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayerViewController (Category)
@property (nonatomic, setter=cp_setOverrideEffectivelyFullScreen:) std::optional<BOOL> cp_overrideEffectivelyFullScreen API_AVAILABLE(visionos(1.0));
@end

NS_ASSUME_NONNULL_END
