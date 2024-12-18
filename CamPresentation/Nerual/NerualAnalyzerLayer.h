//
//  NerualAnalyzerLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>
#import <CamPresentation/NerualAnalyzerModelType.h>
#include <optional>

NS_ASSUME_NONNULL_BEGIN

// 성능을 위해 Thread-safe를 보장하지 않는다. caller에서 보장해줄 것

__attribute__((objc_direct_members))
@interface NerualAnalyzerLayer : CALayer
@property (assign, nonatomic) std::optional<NerualAnalyzerModelType> modelType;
- (void)updateWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

NS_ASSUME_NONNULL_END
