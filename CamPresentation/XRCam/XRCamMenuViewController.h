//
//  XRCamMenuViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/XRCaptureService.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(visionos(1.0))
@interface XRCamMenuViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(XRCaptureService *)captureService;
@end

NS_ASSUME_NONNULL_END
