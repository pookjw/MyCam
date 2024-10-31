//
//  UIDeferredMenuElement+CaptureDevices.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/28/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
@interface UIDeferredMenuElement (CaptureDevices)
+ (instancetype)cp_captureDevicesElementWithCaptureService:(CaptureService *)captureService selectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))selectionHandler deselectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))deselectionHandler;
@end

NS_ASSUME_NONNULL_END
