//
//  CNDetection+CP_Category.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <Cinematic/Cinematic.h>

NS_ASSUME_NONNULL_BEGIN

@interface CNDetection (CP_Category)

@end

NS_ASSUME_NONNULL_END

#endif
