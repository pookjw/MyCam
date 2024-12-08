//
//  PlayerOutputSingleView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/3/24.
//

#import <CamPresentation/PlayerOutputSingleView.h>
#import <CamPresentation/PixelBufferLayerView.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <objc/message.h>
#import <objc/runtime.h>

CA_EXTERN_C_BEGIN
BOOL CAFrameRateRangeIsValid(CAFrameRateRange range);
CA_EXTERN_C_END

@interface PlayerOutputSingleView ()
@property (retain, atomic, nullable) AVPlayerItemVideoOutput *_videoOutput; // SVRunLoop와 Main Thread에서 접근되므로 atomic
@property (retain, nonatomic, readonly) PixelBufferLayer *_pixelBufferLayer;
@property (retain, nonatomic, readonly) SVRunLoop *_renderRunLoop;
@property (retain, nonatomic, readonly) CADisplayLink *_displayLink;
@end

@implementation PlayerOutputSingleView
//@synthesize _videoOutput = __videoOutput;
//@synthesize _pixelBufferLayer = __pixelBufferLayer;
//@synthesize <#property#>

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self _commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _commonInit];
    }
    
    return self;
}

- (void)dealloc {
    [_player release];
    [super dealloc];
}

- (void)_commonInit {
    self.backgroundColor = UIColor.systemCyanColor;
}

@end
