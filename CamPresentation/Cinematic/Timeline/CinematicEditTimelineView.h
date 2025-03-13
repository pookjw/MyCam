//
//  CinematicEditTimelineView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CinematicViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CinematicEditTimelineView;
@protocol CinematicEditTimelineViewDelegate <NSObject>
- (void)cinematicEditTimelineView:(CinematicEditTimelineView *)cinematicEditTimelineView didRequestSeekingTime:(CMTime)time;
@end

@interface CinematicEditTimelineView : UIView
@property (assign, nonatomic, nullable) id<CinematicEditTimelineViewDelegate> delegate;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithParentViewModel:(CinematicViewModel *)parentViewModel;
- (void)scrollToTime:(CMTime)time;
@end

NS_ASSUME_NONNULL_END
