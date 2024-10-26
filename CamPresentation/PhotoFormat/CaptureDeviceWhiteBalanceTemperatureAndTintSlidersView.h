//
//  CaptureDeviceWhiteBalanceTemperatureAndTintSlidersView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/26/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@interface CaptureDeviceWhiteBalanceTemperatureAndTintSlidersView : UIView
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice;
@end

NS_ASSUME_NONNULL_END
