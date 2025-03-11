//
//  CinematicSampleBuffer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicSampleBuffer : NSObject
@property (assign, nonatomic, nullable, readonly) CVPixelBufferRef imageBuffer;
@property (assign, nonatomic, nullable, readonly) CVPixelBufferRef disparityBuffer;
@property (assign, nonatomic, nullable, readonly) CMSampleBufferRef metadataBuffer;
@property (assign, nonatomic, readonly) CMTime presentationTimestamp;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithImageBuffer:(CVPixelBufferRef _Nullable)imageBuffer disparityBuffer:(CVPixelBufferRef _Nullable)disparityBuffer metadataBuffer:(CMSampleBufferRef _Nullable)metadataBuffer presentationTimestamp:(CMTime)presentationTimestamp;
@end

NS_ASSUME_NONNULL_END
