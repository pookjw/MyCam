//
//  TVSwitch.h
//  MyApp
//
//  Created by Jinwoo Kim on 11/24/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(tvos(18.0))
IB_DESIGNABLE
@interface TVSwitch : UIControl
@property(nullable, nonatomic, strong) IBInspectable UIColor *onTintColor UI_APPEARANCE_SELECTOR;
@property(nullable, nonatomic, strong) IBInspectable UIColor *thumbTintColor UI_APPEARANCE_SELECTOR;

@property(nullable, nonatomic, strong) IBInspectable UIImage *onImage UI_APPEARANCE_SELECTOR;
@property(nullable, nonatomic, strong) IBInspectable UIImage *offImage UI_APPEARANCE_SELECTOR;

@property(nullable, nonatomic, copy) IBInspectable NSString *title;

@property(nonatomic, readonly) NSInteger /* UISwitchStyle */ style;
@property(nonatomic) NSInteger /* UISwitchStyle */ preferredStyle;

@property(nonatomic, getter=isOn) IBInspectable BOOL on;
@end

NS_ASSUME_NONNULL_END
