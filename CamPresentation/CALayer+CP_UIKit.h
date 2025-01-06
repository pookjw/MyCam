//
//  CALayer+CP_UIKit.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/6/25.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CALayer (CP_UIKit)
- (UIView * _Nullable)cp_associatedView;
@end

NS_ASSUME_NONNULL_END
