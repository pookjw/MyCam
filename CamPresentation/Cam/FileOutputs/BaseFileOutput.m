//
//  BaseFileOutput.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/BaseFileOutput.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/BaseFileOutput+Private.h>

@implementation BaseFileOutput

- (instancetype)initPrivate {
    if (self = [self init]) {
        
    }
    
    return self;
}

@end

#endif
