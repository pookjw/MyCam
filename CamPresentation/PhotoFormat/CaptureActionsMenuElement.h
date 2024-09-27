//
//  CaptureActionsMenuElement.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/26/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/PhotoFormatModel.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@interface CaptureActionsMenuElement : UIDeferredMenuElement
+ (instancetype)elementWithProvider:(void(^)(void(^completion)(NSArray<UIMenuElement *> *elements)))elementProvider NS_UNAVAILABLE;
+ (instancetype)elementWithUncachedProvider:(void(^)(void(^completion)(NSArray<UIMenuElement *> *elements)))elementProvider NS_UNAVAILABLE;
+ (instancetype)elementWithCaptureService:(CaptureService *)captureService photoFormatModel:(PhotoFormatModel *)photoFormatModel reloadHandler:(void (^ _Nullable)(PhotoFormatModel *photoFormatModel))reloadHandler;
@end

NS_ASSUME_NONNULL_END
