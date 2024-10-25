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
#import <objc/message.h>

@interface MetadataObjectsLayer ()
#if TARGET_OS_VISION
@property (copy, atomic, nullable) NSArray<id> *metadataObjects;
@property (retain, atomic, nullable) __kindof CALayer *previewLayer;
#else
@property (copy, atomic, nullable) NSArray<__kindof AVMetadataObject *> *metadataObjects;
@property (retain, atomic, nullable) AVCaptureVideoPreviewLayer *previewLayer;
#endif
@end

@implementation MetadataObjectsLayer

- (void)dealloc {
    [_metadataObjects release];
    [_previewLayer release];
    [super dealloc];
}

#if TARGET_OS_VISION
- (void)updateWithMetadataObjects:(NSArray<id> *)metadataObjects previewLayer:(__kindof CALayer *)previewLayer
#else
- (void)updateWithMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer
#endif
{
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
    
#if TARGET_OS_VISION
    for (id metadataObject in self.metadataObjects)
#else
    for (__kindof AVMetadataObject *metadataObject in self.metadataObjects)
#endif
    {
        CGRect metadataObjectBounds;
#if TARGET_OS_VISION
        metadataObjectBounds = reinterpret_cast<CGRect (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("bounds"));
#else
        metadataObjectBounds = metadataObject.bounds;
#endif
        
        CGRect rect = [self.previewLayer rectForMetadataOutputRectOfInterest:metadataObjectBounds];
        
#if TARGET_OS_VISION
        NSString *metadataObjectType = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("type"));
#else
        AVMetadataObjectType metadataObjectType = metadataObject.type;
#endif
        
        CGContextStrokeRectWithWidth(ctx, rect, 10.);
        
        CATextLayer *textLayer = [CATextLayer new];
        textLayer.string = metadataObjectType;
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
