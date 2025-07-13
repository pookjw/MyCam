//
//  AVInputPickerInteraction+Category.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_VISION && !TARGET_OS_TV

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVInputPickerInteraction (Category)

@end

NS_ASSUME_NONNULL_END

#endif
