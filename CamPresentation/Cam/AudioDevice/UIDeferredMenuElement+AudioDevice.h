//
//  UIDeferredMenuElement+AudioDevice.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/9/25.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
@interface UIDeferredMenuElement (AudioDevice)
+ (UIDeferredMenuElement *)cp_audioDeviceElementWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice didChangeHandler:(void (^ _Nullable)())didChangeHandler;
@end

NS_ASSUME_NONNULL_END
