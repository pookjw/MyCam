//
//  MetadataObjectsLayer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/20/24.
//

#import <CamPresentation/MetadataObjectsLayer.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MetadataObjectsLayer ()
@property (copy, atomic, nullable) NSArray<__kindof AVMetadataObject *> *metadataObjects;
@property (retain, atomic, nullable) AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation MetadataObjectsLayer

- (void)dealloc {
    [_metadataObjects release];
    [_previewLayer release];
    [super dealloc];
}

- (void)updateWithMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer {
    [SVRunLoop.globalRenderRunLoop runBlock:^{
        self.metadataObjects = metadataObjects;
        self.previewLayer = previewLayer;
        [self setNeedsDisplay];
    }];
}

- (void)drawInContext:(CGContextRef)ctx {
    if (self.metadataObjects == nil || self.previewLayer == nil) return;
    
    CGContextSaveGState(ctx);
    
    CGColorRef color = CGColorCreateSRGB(0., 1., 0., 1.);
    CGContextSetStrokeColorWithColor(ctx, color);
    
    for (__kindof AVMetadataObject *metadataObject in self.metadataObjects) {
        CGRect rect = [self.previewLayer rectForMetadataOutputRectOfInterest:metadataObject.bounds];
        
        CGContextStrokeRectWithWidth(ctx, rect, 10.);
        
        CATextLayer *textLayer = [CATextLayer new];
        textLayer.string = metadataObject.type;
        textLayer.foregroundColor = color;
        textLayer.fontSize = 30.;
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.contentsScale = self.contentsScale;
        textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(rect), 30.);
        
        CGContextSaveGState(ctx);
        CGContextConcatCTM(ctx, CGAffineTransformMakeTranslation(CGRectGetMidX(rect) - CGRectGetWidth(textLayer.frame) * 0.5, CGRectGetMidY(rect) - CGRectGetHeight(textLayer.frame) * 0.5));
        [textLayer renderInContext:ctx];
        [textLayer release];
        CGContextRestoreGState(ctx);
    }
    
    CGColorRelease(color);
    
    CGContextRestoreGState(ctx);
}

@end
