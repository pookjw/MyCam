//
//  MetadataObjectsLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/20/24.
//

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetadataObjectsLayer : CALayer
#if TARGET_OS_VISION
- (void)updateWithMetadataObjects:(NSArray<id> *)metadataObjects previewLayer:(__kindof CALayer *)previewLayer;
#else
- (void)updateWithMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer;
#endif
@end

NS_ASSUME_NONNULL_END
