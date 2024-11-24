//
//  TVStepper.h
//  MyApp
//
//  Created by Jinwoo Kim on 11/23/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(tvos(18.0))
IB_DESIGNABLE
@interface TVStepper : UIView
@property (nonatomic,getter=isContinuous) IBInspectable BOOL continuous;
@property (nonatomic) IBInspectable BOOL autorepeat;
@property (nonatomic) IBInspectable BOOL wraps;
@property (nonatomic) IBInspectable double value;
@property (nonatomic) IBInspectable double minimumValue;
@property (nonatomic) IBInspectable double maximumValue;
@property (nonatomic) IBInspectable double stepValue;

- (void)addAction:(UIAction *)action;
- (void)removeAction:(UIAction *)action;
@end

NS_ASSUME_NONNULL_END
