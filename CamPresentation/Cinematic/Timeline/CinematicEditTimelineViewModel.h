//
//  CinematicEditTimelineViewModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import <CamPresentation/CinematicViewModel.h>
#import <CamPresentation/CinematicEditTimelineSectionModel.h>
#import <CamPresentation/CinematicEditTimelineItemModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineViewModel : NSObject
@property (retain, nonatomic, readonly, nullable) CinematicSnapshot *mainQueue_cinematicSnapshot;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithParentViewModel:(CinematicViewModel *)parentViewModel dataSource:(UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel *, CinematicEditTimelineItemModel *> *)dataSource;
@end

NS_ASSUME_NONNULL_END

#endif
