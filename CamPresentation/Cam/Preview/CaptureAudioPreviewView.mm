//
//  CaptureAudioPreviewView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/CaptureAudioPreviewView.h>

@interface CaptureAudioPreviewView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@end

@implementation CaptureAudioPreviewView

- (instancetype)initWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice audioWaveLayer:(AudioWaveLayer *)audioWaveLayer {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _audioDevice = [audioDevice retain];
        _audioWaveLayer = [audioWaveLayer retain];
        
        self.backgroundColor = UIColor.systemPinkColor;
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_audioDevice release];
    [_audioWaveLayer release];
    [super dealloc];
}

@end

#endif
