//
//  CaptureDevicesMenuBuilder.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/18/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@class CaptureDevicesMenuBuilder;
@protocol CaptureDevicesMenuBuilderDelegate <NSObject>
- (void)captureDevicesMenuBuilderElementsDidChange:(CaptureDevicesMenuBuilder *)captureDevicesMenuBuilder;
@end

@interface CaptureDevicesMenuBuilder : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService delegate:(id<CaptureDevicesMenuBuilderDelegate>)delegate;
- (void)menuElementsWithCompletionHandler:(void (^ _Nullable)(NSArray<__kindof UIMenuElement *> *menuElements))completionHandler;
@end

NS_ASSUME_NONNULL_END
