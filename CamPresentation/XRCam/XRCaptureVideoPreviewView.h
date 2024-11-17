//
//  XRCaptureVideoPreviewView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(visionos(1.0))
@interface XRCaptureVideoPreviewView : UIView
@property (retain, nonatomic, nullable) __kindof CALayer *previewLayer;
@end

NS_ASSUME_NONNULL_END
