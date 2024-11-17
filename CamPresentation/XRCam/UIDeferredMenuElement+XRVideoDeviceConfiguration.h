//
//  UIDeferredMenuElement+XRVideoDeviceConfiguration.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/XRCaptureService.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(visionos(1.0))
@interface UIDeferredMenuElement (XRVideoDeviceConfiguration)
+ (instancetype)cp_xr_videoDeviceConfigurationElementWithCaptureService:(XRCaptureService *)captureService videoDevice:(AVCaptureDevice *)videoDevice didChangeHandler:(void (^ _Nullable)())didChangeHandler;
@end

NS_ASSUME_NONNULL_END
