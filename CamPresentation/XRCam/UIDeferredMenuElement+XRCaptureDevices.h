//
//  UIDeferredMenuElement+XRCaptureDevices.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/XRCaptureService.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(visionos(1.0))
@interface UIDeferredMenuElement (XRCaptureDevices)
+ (instancetype)cp_xr_captureDevicesElementWithCaptureService:(XRCaptureService *)captureService selectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))selectionHandler deselectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))deselectionHandler;
@end

NS_ASSUME_NONNULL_END
