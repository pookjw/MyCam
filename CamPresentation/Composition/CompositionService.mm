//
//  CompositionService.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/16/25.
//

#import <CamPresentation/CompositionService.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <objc/objc-sync.h>

@interface CompositionService ()
@property (class, nonatomic, getter=_archivedComposition, setter=_setArchivedComposition:) AVComposition *archivedComposition;
@property (copy, nonatomic, getter=queue_composition, setter=_queue_setComposition:) AVComposition *queue_composition;
@property (retain, nonatomic, getter=_queue_mutableComposition, setter=_queue_setMutableComposition:) AVMutableComposition *queue_mutableComposition;
@end

@implementation CompositionService
@synthesize queue_composition = _queue_composition;
@synthesize queue_mutableComposition = _queue_mutableComposition;

+ (AVComposition *)_archivedComposition {
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

+ (void)_setArchivedComposition:(AVComposition *)composition {
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

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        _queue = dispatch_queue_create("Composition Service Queue", attr);
        
        _queue_composition = [[AVComposition alloc] init];
        _queue_mutableComposition = [[AVMutableComposition alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    dispatch_release(_queue);
    [_queue_composition release];
    [_queue_mutableComposition release];
    [super dealloc];
}

- (AVComposition *)queue_composition {
    dispatch_assert_queue(self.queue);
    return [[_queue_composition retain] autorelease];
}

- (void)_queue_setComposition:(AVComposition *)composition {
    dispatch_assert_queue(self.queue);
    assert(composition != nil);
    
    [_queue_composition release];
    _queue_composition = [composition copy];
}

- (AVMutableComposition *)_queue_mutableComposition {
    dispatch_assert_queue(self.queue);
    return _queue_mutableComposition;
}

- (void)_queue_setMutableComposition:(AVMutableComposition *)mutableComposition {
    dispatch_assert_queue(self.queue);
    assert(mutableComposition != nil);
    
    [_queue_mutableComposition release];
    _queue_mutableComposition = [mutableComposition retain];
}

- (void)queue_loadLastComposition {
    dispatch_assert_queue(self.queue);
    
    AVComposition * _Nullable composition = CompositionService.archivedComposition;
    if (composition == nil) return;
    
    AVMutableComposition *mutableComposition = [composition mutableCopy];
    self.queue_mutableComposition = mutableComposition;
    [mutableComposition release];
    
    self.queue_composition = composition;
}

- (void)queue_addVideoSegmentsFromPHAssets:(NSArray<PHAsset *> *)phAssets {
    dispatch_assert_queue(self.queue);
    abort();
}

@end
