//
//  CinematicSampleBuffer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicSampleBuffer.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

@implementation CinematicSampleBuffer

- (instancetype)initWithImageBuffer:(CVPixelBufferRef)imageBuffer disparityBuffer:(CVPixelBufferRef)disparityBuffer metadataBuffer:(CMSampleBufferRef)metadataBuffer presentationTimestamp:(CMTime)presentationTimestamp {
    if (self = [super init]) {
        _imageBuffer = CVPixelBufferRetain(imageBuffer);
        _disparityBuffer = CVPixelBufferRetain(disparityBuffer);
        if (metadataBuffer) {
            _metadataBuffer = (CMSampleBufferRef)CFRetain(metadataBuffer);
        }
        _presentationTimestamp = presentationTimestamp;
    }
    
    return self;
}

- (void)dealloc {
    CVPixelBufferRelease(_imageBuffer);
    CVPixelBufferRelease(_disparityBuffer);
    if (CMSampleBufferRef metadataBuffer = _metadataBuffer) {
        CFRelease(metadataBuffer);
    }
    [super dealloc];
}

@end

#endif
