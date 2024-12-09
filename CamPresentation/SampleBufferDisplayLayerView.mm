//
//  SampleBufferDisplayLayerView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/9/24.
//

#import <CamPresentation/SampleBufferDisplayLayerView.h>

@implementation SampleBufferDisplayLayerView

+ (Class)layerClass {
    return [AVSampleBufferDisplayLayer class];
}

- (AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer {
    return static_cast<AVSampleBufferDisplayLayer *>(self.layer);
}

@end
