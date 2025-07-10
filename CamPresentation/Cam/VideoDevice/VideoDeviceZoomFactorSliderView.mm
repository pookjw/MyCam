//
//  VideoDeviceZoomFactorSliderView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/10/25.
//

#import "VideoDeviceZoomFactorSliderView.h"

#warning TODO

@interface VideoDeviceZoomFactorSliderView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *videoDevice;
@end

@implementation VideoDeviceZoomFactorSliderView

- (instancetype)initWithCaptureService:(CaptureService *)captureService videoDevice:(AVCaptureDevice *)videoDevice {
    if (self = [super initWithFrame:CGRectNull]) {
        
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_videoDevice release];
    [super dealloc];
}

@end
