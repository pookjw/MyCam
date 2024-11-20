//
//  VolumeSlider.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/17/24.
//

#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if !TARGET_OS_TV

@interface VolumeSlider : UISlider

@end

#endif

NS_ASSUME_NONNULL_END
