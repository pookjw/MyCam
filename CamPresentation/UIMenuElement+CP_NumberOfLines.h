//
//  UIMenuElement+CP_NumberOfLines.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/18/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIMenuElement (CP_NumberOfLines)
@property (copy, nonatomic, nullable, setter=cp_setOverrideNumberOfTitleLines:) NSNumber *cp_overrideNumberOfTitleLines;
@property (copy, nonatomic, nullable, setter=cp_setOverrideNumberOfSubtitleLines:) NSNumber *cp_overrideNumberOfSubtitleLines;
@end

NS_ASSUME_NONNULL_END
