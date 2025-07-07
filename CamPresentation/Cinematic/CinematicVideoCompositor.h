//
//  CinematicVideoCompositor.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicVideoCompositor : NSObject <AVVideoCompositing>

@end

NS_ASSUME_NONNULL_END

#endif
