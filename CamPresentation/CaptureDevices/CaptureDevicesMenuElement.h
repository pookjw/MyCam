//
//  CaptureDevicesMenuElement.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/27/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@interface CaptureDevicesMenuElement : UIDeferredMenuElement
+ (instancetype)elementWithProvider:(void(^)(void(^completion)(NSArray<UIMenuElement *> *elements)))elementProvider NS_UNAVAILABLE;
+ (instancetype)elementWithUncachedProvider:(void(^)(void(^completion)(NSArray<UIMenuElement *> *elements)))elementProvider NS_UNAVAILABLE;
+ (instancetype)elementWithCaptureDevice:(CaptureService *)captureDevice selectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))selectionHandler deselectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))deselectionHandler reloadHandler:(void (^ _Nullable)())reloadHandler;
@end

NS_ASSUME_NONNULL_END
