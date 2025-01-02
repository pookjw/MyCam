//
//  ImageVision3DDescriptor.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/2/25.
//

#import <CamPresentation/ImageVision3DDescriptor.h>

@implementation ImageVision3DDescriptor

- (instancetype)initWithHumanBodyPose3DObservations:(NSArray<VNHumanBodyPose3DObservation *> *)humanBodyPose3DObservations image:(UIImage *)image {
    if (self = [super init]) {
        _humanBodyPose3DObservations = [humanBodyPose3DObservations copy];
        _image = [image retain];
    }
    
    return self;
}

- (void)dealloc {
    [_humanBodyPose3DObservations release];
    [_image release];
    [super dealloc];
}

@end
