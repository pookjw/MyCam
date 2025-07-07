//
//  CinematicCompileTimeLinker.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/7/25.
//

#import <CamPresentation/CinematicCompileTimeLinker.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <Cinematic/Cinematic.h>

@implementation CinematicCompileTimeLinker

+ (void)load {
    [CNCompositionInfo class];
}

@end

#endif
