//
//  UIDeferredMenuElement+PhotoFormat.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/29/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>
#import <CamPresentation/PhotoFormatModel.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
@interface UIDeferredMenuElement (PhotoFormat)
+ (instancetype)cp_photoFormatElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^ _Nullable)())didChangeHandler;
@end

NS_ASSUME_NONNULL_END
