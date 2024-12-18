//
//  NerualAnalyzerLayer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <CamPresentation/NerualAnalyzerLayer.h>
#import <UIKit/UIKit.h>

__attribute__((objc_direct_members))
@interface NerualAnalyzerLayer ()

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

- (void)updateWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    NSLog(@"TODO %@", NSStringFromNerualAnalyzerModelType(self.modelType.value()));
}

- (void)drawInContext:(CGContextRef)ctx {
    
}

@end
