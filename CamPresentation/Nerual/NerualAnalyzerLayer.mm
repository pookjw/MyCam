//
//  NerualAnalyzerLayer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <CamPresentation/NerualAnalyzerLayer.h>
#import <CoreML/CoreML.h>

__attribute__((objc_direct_members))
@interface NerualAnalyzerLayer ()
@property (retain, nonatomic, nullable) MLModel *_model;
@end

@implementation NerualAnalyzerLayer

- (instancetype)initWithLayer:(id)layer {
    if (![layer isKindOfClass:[NerualAnalyzerLayer class]]) {
        [self release];
        self = nil;
        return nil;
    }
    
    auto casted = static_cast<NerualAnalyzerLayer *>(layer);
    
    if (self = [super initWithLayer:casted]) {
        _modelType = casted->_modelType;
    }
    
    return self;
}

- (void)dealloc {
    [__model release];
    [super dealloc];
}

- (void)setModelType:(std::optional<NerualAnalyzerModelType>)modelType {
    _modelType = modelType;
    
    if (auto ptr = modelType) {
        NerualAnalyzerModelType modelType = *ptr;
        
        MLModelConfiguration *configuration = [MLModelConfiguration new];
        configuration.modelDisplayName = NSStringFromNerualAnalyzerModelType(modelType);
        configuration.allowLowPrecisionAccumulationOnGPU = NO;
        configuration.computeUnits = MLComputeUnitsAll;
        
        MLOptimizationHints * optimizationHints = [MLOptimizationHints new];
        optimizationHints.reshapeFrequency = MLReshapeFrequencyHintInfrequent;
        optimizationHints.specializationStrategy = MLSpecializationStrategyFastPrediction;
        
        configuration.optimizationHints = optimizationHints;
        [optimizationHints release];
        
        NSURL *url = mlmodelcURLFromNerualAnalyzerModelType(modelType);
    } else {
        self._model = nil;
    }
}

- (void)updateWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    NSLog(@"TODO %@", NSStringFromNerualAnalyzerModelType(self.modelType.value()));
}

- (void)drawInContext:(CGContextRef)ctx {
    
}

@end
