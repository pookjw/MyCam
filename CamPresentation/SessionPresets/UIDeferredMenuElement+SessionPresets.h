//
//  UIDeferredMenuElement+SessionPresets.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/16/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDeferredMenuElement (SessionPresets)
+ (instancetype)cp_sessionPresetsElementWithCaptureService:(CaptureService *)captureService didChangeHandler:(void (^ _Nullable)())didChangeHandler;
@end

NS_ASSUME_NONNULL_END
