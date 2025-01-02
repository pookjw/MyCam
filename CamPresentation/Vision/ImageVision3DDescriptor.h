//
//  ImageVision3DDescriptor.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/2/25.
//

#import <UIKit/UIKit.h>
#import <Vision/Vision.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageVision3DDescriptor : NSObject
@property (copy, nonatomic, readonly) NSArray<VNHumanBodyPose3DObservation *> *humanBodyPose3DObservations;
@property (retain, nonatomic, readonly) UIImage *image;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithHumanBodyPose3DObservations:(NSArray<VNHumanBodyPose3DObservation *> *)humanBodyPose3DObservations image:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
