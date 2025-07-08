//
//  UIDeferredMenuElement+AudioDevices.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/9/25.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
@interface UIDeferredMenuElement (AudioDevices)
+ (UIDeferredMenuElement *)cp_audioDevicesElementWithCaptureService:(CaptureService *)captureService didChangeHandler:(void (^ _Nullable)())didChangeHandler;
@end

NS_ASSUME_NONNULL_END
