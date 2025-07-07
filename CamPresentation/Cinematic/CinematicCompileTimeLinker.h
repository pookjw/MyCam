//
//  CinematicCompileTimeLinker.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/7/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicCompileTimeLinker : NSObject

@end

NS_ASSUME_NONNULL_END

#endif
