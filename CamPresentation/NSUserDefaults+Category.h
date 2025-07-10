//
//  NSUserDefaults+Category.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSUserDefaults (Category)
@property (assign, nonatomic, getter=cp_isDeferredStartEnabled, setter=cp_setDeferredStartEnabled:) BOOL cp_deferredStartEnabled API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), visionos(26.0), macos(26.0));
@end

NS_ASSUME_NONNULL_END
