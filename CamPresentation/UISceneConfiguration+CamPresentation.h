//
//  UISceneConfiguration+CamPresentation.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/19/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UISceneConfiguration (CamPresentation)
+ (UISceneConfiguration * _Nullable)cp_sceneConfigurationWithOptions:(UISceneConnectionOptions *)options;
@end

NS_ASSUME_NONNULL_END
