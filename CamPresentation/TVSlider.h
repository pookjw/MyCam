//
//  TVSlider.h
//  MyApp
//
//  Created by Jinwoo Kim on 11/21/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(tvos(18.0))
NS_SWIFT_UI_ACTOR
IB_DESIGNABLE
@interface TVSlider : UIView
@property (nonatomic) IBInspectable float value;
@property (nonatomic) IBInspectable float minimumValue;
@property (nonatomic) IBInspectable float maximumValue;
@property (nonatomic) IBInspectable float stepValue;

@property (nonatomic, getter=isEnabled) IBInspectable BOOL enabled;
@property (nonatomic, getter=isContinuous) IBInspectable BOOL continuous;
@property (nonatomic, readonly, getter=isEditing) BOOL editing;

@property (retain, nonatomic, nullable) IBInspectable UIColor *minimumTrackTintColor UI_APPEARANCE_SELECTOR;
@property (retain, nonatomic, nullable) IBInspectable UIColor *maximumTrackTintColor UI_APPEARANCE_SELECTOR;
@property (retain, nonatomic, nullable) IBInspectable UIColor *thumbTintColor UI_APPEARANCE_SELECTOR;

- (void)setValue:(float)value animated:(BOOL)animated;

@property (nonatomic, readonly) NSArray<UIAction *> *actions;

- (void)addAction:(UIAction *)action NS_SWIFT_NAME(addAction(_:));
- (void)removeAction:(UIAction *)action NS_SWIFT_NAME(removeAction(_:));
@end

NS_ASSUME_NONNULL_END
