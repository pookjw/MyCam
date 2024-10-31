//
//  CaptureDeviceExposureSlidersView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@interface CaptureDeviceExposureSlidersView : UIView
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
