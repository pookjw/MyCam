//
//  CinematicEditTimelineViewModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CinematicViewModel.h>
#import <CamPresentation/CinematicEditTimelineSectionModel.h>
#import <CamPresentation/CinematicEditTimelineItemModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineViewModel : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithParentViewModel:(CinematicViewModel *)parentViewModel dataSource:(UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel *, CinematicEditTimelineItemModel *> *)dataSource;
@end

NS_ASSUME_NONNULL_END
