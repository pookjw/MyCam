//
//  CinematicEditHelper.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <Cinematic/Cinematic.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface CinematicEditHelper : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)drawRectsForCNScriptFrame:(CNScriptFrame *)cinematicScriptFrame outputBuffer:(CVPixelBufferRef)outputBuffer stringDecision:(BOOL)strongDecision rectDrawCommandBuffer:(id<MTLCommandBuffer>)rectDrawCommandBuffer preferredTransform:(CGAffineTransform)preferredTransform;
@end

NS_ASSUME_NONNULL_END
