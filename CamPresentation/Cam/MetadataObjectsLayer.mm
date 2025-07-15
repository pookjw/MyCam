//
//  MetadataObjectsLayer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/20/24.
//

#import <CamPresentation/MetadataObjectsLayer.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/SVRunLoop.hpp>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/NSStringFromAVCaptureCinematicVideoFocusMode.h>

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
        
        //
        
        if ([metadataObject.type isEqualToString:AVMetadataObjectTypeFace]) {
            BOOL hasPayingAttention = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("hasPayingAttention"));
            BOOL hasPayingAttentionConfidence = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("hasPayingAttentionConfidence"));
            
            BOOL hasLeftEyeBounds = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("hasLeftEyeBounds"));
            BOOL hasLeftEyeClosedConfidence = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("hasLeftEyeClosedConfidence"));
            
            BOOL hasRightEyeBounds = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("hasRightEyeBounds"));
            BOOL hasRightEyeClosedConfidence = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("hasRightEyeClosedConfidence"));
            
            
            if (hasPayingAttention) {
                double payingAttentionConfidence;
                if (hasPayingAttentionConfidence) {
                    payingAttentionConfidence = reinterpret_cast<double (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("payingAttentionConfidence"));
                } else {
                    payingAttentionConfidence = 1.;
                }
                
                CGColorRef color = CGColorCreateSRGB(1., 0., 0., payingAttentionConfidence);
                CGContextSetStrokeColorWithColor(ctx, color);
                CGColorRelease(color);
                
                CGRect insetsRect = CGRectInset(rect, 10., 10.);
                CGContextStrokeRectWithWidth(ctx, insetsRect, 10.);
            }
            
            if (hasLeftEyeBounds) {
                CGRect leftEyeBounds = reinterpret_cast<CGRect (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("leftEyeBounds"));
                
                CGFloat opacity;
                if (hasLeftEyeClosedConfidence) {
                    int leftEyeClosedConfidence = reinterpret_cast<int (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("leftEyeClosedConfidence"));
                    opacity = (CGFloat)(100 - leftEyeClosedConfidence) / 100.;
                } else {
                    opacity = 1.;
                }
                
                CGRect rect = [self.previewLayer rectForMetadataOutputRectOfInterest:leftEyeBounds];
                
                CGColorRef color = CGColorCreateSRGB(1., 0., 0., opacity);
                CGContextSetStrokeColorWithColor(ctx, color);
                CGColorRelease(color);
                
                CGRect insetsRect = CGRectInset(rect, 10., 10.);
                CGContextStrokeRectWithWidth(ctx, insetsRect, 10.);
            }
            
            if (hasRightEyeBounds) {
                CGRect rightEyeBounds = reinterpret_cast<CGRect (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("rightEyeBounds"));
                
                CGFloat opacity;
                if (hasRightEyeClosedConfidence) {
                    int rightEyeClosedConfidence = reinterpret_cast<int (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("rightEyeClosedConfidence"));
                    opacity = (CGFloat)(100 - rightEyeClosedConfidence) / 100.;
                } else {
                    opacity = 1.;
                }
                
                CGRect rect = [self.previewLayer rectForMetadataOutputRectOfInterest:rightEyeBounds];
                
                CGColorRef color = CGColorCreateSRGB(1., 0., 0., opacity);
                CGContextSetStrokeColorWithColor(ctx, color);
                CGColorRelease(color);
                
                CGRect insetsRect = CGRectInset(rect, 10., 10.);
                CGContextStrokeRectWithWidth(ctx, insetsRect, 10.);
            }
        }
        
        //
        
        CATextLayer *textLayer = [CATextLayer new];
        
        NSMutableString *string = [NSMutableString new];
        if ([metadataObject.type isEqualToString:AVMetadataObjectTypeFace]) {
            BOOL hasSmileConfidence = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("hasSmileConfidence"));
            
            if (hasSmileConfidence) {
                int smileConfidence = reinterpret_cast<int (*)(id, SEL)>(objc_msgSend)(metadataObject, sel_registerName("smileConfidence"));
                [string appendFormat:@"%@ (smile: %d)", metadataObject.type, smileConfidence];
            }
        }
        [string appendString:metadataObject.type];
        
        if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
            AVCaptureCinematicVideoFocusMode cinematicVideoFocusMode = metadataObject.cinematicVideoFocusMode;
            [string appendFormat:@"(%@)", NSStringFromAVCaptureCinematicVideoFocusMode(cinematicVideoFocusMode)];
            
            if (metadataObject.fixedFocus) {
                [string appendString:@"\nFixed Focus"];
            }
        }
        
        textLayer.string = string;
        [string release];
        textLayer.foregroundColor = color;
        textLayer.fontSize = 10.;
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

#endif
