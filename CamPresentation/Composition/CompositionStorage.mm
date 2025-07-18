//
//  CompositionStorage.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/18/25.
//

#import <CamPresentation/CompositionStorage.h>
#include <objc/objc-sync.h>

@implementation CompositionStorage

+ (AVComposition *)composition {
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    
    assert(objc_sync_enter(userDefaults) == OBJC_SYNC_SUCCESS);
    
    NSData * _Nullable data = [userDefaults objectForKey:@"cp_compositionData"];
    if (data == nil) {
        assert(objc_sync_exit(userDefaults) == OBJC_SYNC_SUCCESS);
        return nil;
    }
    
    NSError * _Nullable error = nil;
    AVComposition *composition = [NSKeyedUnarchiver unarchivedObjectOfClass:[AVComposition class] fromData:data error:&error];
    
    assert(objc_sync_exit(userDefaults) == OBJC_SYNC_SUCCESS);
    assert(composition != nil);
    
    return composition;
}

+ (void)setComposition:(AVComposition *)composition {
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    
    assert(objc_sync_enter(userDefaults) == OBJC_SYNC_SUCCESS);
    
    if (composition == nil) {
        [userDefaults setObject:nil forKey:@"cp_compositionData"];
    } else {
        NSError * _Nullable error = nil;
        NSData * _Nullable data = [NSKeyedArchiver archivedDataWithRootObject:composition requiringSecureCoding:YES error:&error];
        assert(data != nil);
        [userDefaults setObject:data forKey:@"cp_compositionData"];
    }
    
    assert(objc_sync_exit(userDefaults) == OBJC_SYNC_SUCCESS);
}

@end
