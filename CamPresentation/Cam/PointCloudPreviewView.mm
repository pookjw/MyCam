//
//  PointCloudPreviewView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/19/24.
//

#import <CamPresentation/PointCloudPreviewView.h>

@implementation PointCloudPreviewView

- (instancetype)initWithPointCloudLayer:(CALayer *)pointCloudLayer {
    if (self = [super initWithFrame:CGRectNull]) {
        _pointCloudLayer = [pointCloudLayer retain];
        
        CALayer *layer = self.layer;
        CGRect bounds = self.layer.bounds;
        pointCloudLayer.frame = bounds;
        [layer addSublayer:pointCloudLayer];
    }
    
    return self;
}

- (void)dealloc {
    [_pointCloudLayer release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.layer.bounds;
    self.pointCloudLayer.frame = bounds;
}

@end
