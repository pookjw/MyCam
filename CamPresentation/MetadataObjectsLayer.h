//
//  MetadataObjectsLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/20/24.
//

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetadataObjectsLayer : CALayer
- (void)updateWithMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer;
@end

NS_ASSUME_NONNULL_END
