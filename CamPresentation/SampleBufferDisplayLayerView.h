//
//  SampleBufferDisplayLayerView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/9/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SampleBufferDisplayLayerView : UIView
@property (nonatomic, readonly) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
@end

NS_ASSUME_NONNULL_END