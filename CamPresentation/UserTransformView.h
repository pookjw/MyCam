//
//  UserTransformView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/7/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class UserTransformView;
@protocol UserTransformViewDelegate <NSObject>
- (void)userTransformView:(UserTransformView *)userTransformView didChangeUserAffineTransform:(CGAffineTransform)userAffineTransform isUserInteracting:(BOOL)isUserInteracting;
@optional - (BOOL)userTransformView:(UserTransformView *)userTransformView shouldReceiveTouchAtPoint:(CGPoint)point;
@end

@interface UserTransformView : UIView
@property (assign, nonatomic) struct CGSize contentPixelSize;
@property (assign, nonatomic) struct CGRect untransformedContentFrame;
@property (assign, nonatomic) BOOL preferToFillOnDoubleTap;
@property (assign, nonatomic) BOOL hasUserZoomedIn;
@property (assign, nonatomic) id<UserTransformViewDelegate> delegate;
- (void)zoomInOnLocationFromProvider:(__kindof UIGestureRecognizer *)provider animated:(BOOL)animated;
- (void)zoomOut:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END
