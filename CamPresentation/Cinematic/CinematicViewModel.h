//
//  CinematicViewModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <Photos/Photos.h>
#import <Cinematic/Cinematic.h>
#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <CamPresentation/CinematicAssetData.h>
#import <CamPresentation/CinematicSnapshot.h>
#import <CamPresentation/Extern.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSNotificationName const CinematicViewModelDidUpdateScriptNotification;

@interface CinematicViewModel : NSObject
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@property (retain, nonatomic, readonly, nullable) CinematicSnapshot *isolated_snapshot;
- (void)isolated_loadWithData:(CinematicAssetData *)data;
- (void)isolated_changeFocusAtNormalizedPoint:(CGPoint)normalizedPoint atTime:(CMTime)time strongDecision:(BOOL)strongDecision;
- (void)isolated_changeFNumber:(float)fNumber;
@end

NS_ASSUME_NONNULL_END
