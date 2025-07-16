//
//  CompositionService.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/16/25.
//

#import <CamPresentation/CompositionService.h>

NSNotificationName const CompositionServiceDidCommitNotificationName = @"CompositionServiceDidCommitNotificationName";

NSString * const CompositionServiceCompositionKey = @"composition";

@interface CompositionService ()
@property (retain, nonatomic, nullable, getter=_queue_mutableComposition, setter=_queue_setMutableComposition:) AVMutableComposition *queue_mutableComposition;
@end

@implementation CompositionService

- (instancetype)init {
    if (self = [super init]) {
        {
            dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
            _queue = dispatch_queue_create("Composition Service Queue", attr);
        }
    }
    
    return self;
}

- (void)dealloc {
    dispatch_release(_queue);
    [_queue_mutableComposition release];
    [super dealloc];
}

- (AVComposition *)queue_composition {
    dispatch_assert_queue(self.queue);
    return [[_queue_mutableComposition copy] autorelease];
}

@end
