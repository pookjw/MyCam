//
//  CompositionService.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/16/25.
//

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <CamPresentation/Extern.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSNotificationName const CompositionServiceDidCommitNotificationName /* CompositionServiceCompositionKey */;

CP_EXTERN NSString * const CompositionServiceCompositionKey;

@interface CompositionService : NSObject
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@property (copy, nonatomic, nullable, readonly) AVComposition *queue_composition;
@end

NS_ASSUME_NONNULL_END
