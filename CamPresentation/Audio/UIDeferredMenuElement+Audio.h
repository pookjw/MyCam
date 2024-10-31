//
//  UIDeferredMenuElement+Audio.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/14/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDeferredMenuElement (Audio)
+ (instancetype)cp_audioElementWithDidChangeHandler:(void (^ _Nullable)())didChangeHandler;
@end

NS_ASSUME_NONNULL_END
