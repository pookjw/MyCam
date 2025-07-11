//
//  CaptureAudioPreviewView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <CamPresentation/CaptureAudioPreviewView.h>

@interface CaptureAudioPreviewView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *audioDevice;
@end

@implementation CaptureAudioPreviewView

- (instancetype)initWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _audioDevice = [audioDevice retain];
        
        self.backgroundColor = UIColor.systemPinkColor;
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_audioDevice release];
    [super dealloc];
}

@end
