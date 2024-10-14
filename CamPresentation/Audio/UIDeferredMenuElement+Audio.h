//
//  UIDeferredMenuElement+Audio.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/14/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDeferredMenuElement (Audio)
+ (instancetype)cp_audioElementWithCaptureService:(CaptureService *)captureService didChangeHandler:(void (^ _Nullable)())didChangeHandler;
@end

NS_ASSUME_NONNULL_END
