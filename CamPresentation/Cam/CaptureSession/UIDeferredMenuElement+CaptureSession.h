//
//  UIDeferredMenuElement+CaptureSession.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/19/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDeferredMenuElement (CaptureSession)
+ (instancetype)cp_captureSessionConfigurationElementWithCaptureService:(CaptureService *)captureService didChangeHandler:(void (^ _Nullable)())didChangeHandler;
@end

NS_ASSUME_NONNULL_END
