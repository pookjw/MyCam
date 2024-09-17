//
//  CaptureDevicesMenuService.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/18/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@class CaptureDevicesMenuService;
@protocol CaptureDevicesMenuServiceDelegate <NSObject>
- (void)captureDevicesMenuServiceElementsDidChange:(CaptureDevicesMenuService *)captureDevicesMenuService;
@end

@interface CaptureDevicesMenuService : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService delegate:(id<CaptureDevicesMenuServiceDelegate>)delegate;
- (void)menuElementsWithCompletionHandler:(void (^ _Nullable)(NSArray<__kindof UIMenuElement *> *menuElements))completionHandler;
@end

NS_ASSUME_NONNULL_END
