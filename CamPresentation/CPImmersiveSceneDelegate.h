//
//  CPImmersiveSceneDelegate.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/19/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(visionos(1.0))
@interface CPImmersiveSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

NS_ASSUME_NONNULL_END
