//
//  CinematicEditHelper.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicEditHelper.h>

@interface CinematicEditHelper ()
@property (retain, nonatomic, readonly, getter=_device) id<MTLDevice> device;
@end

@implementation CinematicEditHelper

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _device = [device retain];
    }
    
    return self;
}

- (void)dealloc {
    [_device release];
    [super dealloc];
}

@end
