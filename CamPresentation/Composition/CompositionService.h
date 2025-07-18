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

@interface CompositionService : NSObject
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@property (copy, nonatomic, readonly) AVComposition *queue_composition;
- (void)queue_loadComposition;
- (void)queue_resetComposition;
- (NSProgress *)nonisolated_addVideoSegmentsFromPHAssets:(NSArray<PHAsset *> *)phAssets;
@end

NS_ASSUME_NONNULL_END
