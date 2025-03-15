//
//  CinematicEditTimelineDecisionContentView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/12/25.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CinematicEditTimelineItemModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineDecisionContentConfiguration : NSObject <UIContentConfiguration>
@property (retain, nonatomic, readonly) CinematicEditTimelineItemModel *itemModel;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithItemModel:(CinematicEditTimelineItemModel *)itemModel;
@end

@interface CinematicEditTimelineDecisionContentView : UIView <UIContentView>

@end

NS_ASSUME_NONNULL_END
