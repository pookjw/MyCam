//
//  NSUserDefaults+Category.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <CamPresentation/NSUserDefaults+Category.h>

#define DEFERRED_START_ENABLED @"CamPresentation_deferredStartEnabled"

@implementation NSUserDefaults (Category)

- (BOOL)cp_isDeferredStartEnabled {
    return [self boolForKey:DEFERRED_START_ENABLED];
}

- (void)cp_setDeferredStartEnabled:(BOOL)deferredStartEnabled {
    [self setBool:deferredStartEnabled forKey:DEFERRED_START_ENABLED];
}

@end
