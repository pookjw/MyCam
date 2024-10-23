//
//  FocusRectLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <CamPresentation/FocusRectLayer.h>

@interface FocusRectLayer ()
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@end

@implementation FocusRectLayer

- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    if (self = [super init]) {
        _captureDevice = [captureDevice retain];
    }
    
    return self;
}

- (instancetype)initWithLayer:(id)layer {
    assert([layer isKindOfClass:FocusRectLayer.class]);
    
    if (self = [super initWithLayer:layer]) {
        auto casted = static_cast<FocusRectLayer *>(self);
        _captureDevice = [casted->_captureDevice retain];
    }
    
    return self;
}

- (void)dealloc {
    [_captureDevice release];
    [super dealloc];
}

@end
