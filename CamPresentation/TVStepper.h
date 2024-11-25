//
//  TVStepper.h
//  MyApp
//
//  Created by Jinwoo Kim on 11/23/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(tvos(18.0))
NS_SWIFT_UI_ACTOR
IB_DESIGNABLE
@interface TVStepper : UIView
@property (nonatomic,getter=isContinuous) IBInspectable BOOL continuous;
@property (nonatomic) IBInspectable BOOL autorepeat;
@property (nonatomic) IBInspectable BOOL wraps;
@property (nonatomic) IBInspectable double value;
@property (nonatomic) IBInspectable double minimumValue;
@property (nonatomic) IBInspectable double maximumValue;
@property (nonatomic) IBInspectable double stepValue;
@property (nonatomic, getter=isEnabled) IBInspectable BOOL enabled;
@property (nonatomic, readonly, getter=isEditing) BOOL editing;
@property (nonatomic, readonly) NSArray<UIAction *> *actions;

- (void)addAction:(UIAction *)action NS_SWIFT_NAME(addAction(_:));
- (void)removeAction:(UIAction *)action NS_SWIFT_NAME(removeAction(_:));
@end

NS_ASSUME_NONNULL_END
