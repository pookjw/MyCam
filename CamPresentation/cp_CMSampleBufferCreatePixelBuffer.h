//
//  cp_CMSampleBufferCreatePixelBuffer.h
//  MyCam
//
//  Created by Jinwoo Kim on 1/5/25.
//

#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

CMSampleBufferRef cp_CMSampleBufferCreatePixelBuffer(CVPixelBufferRef pixelBufferRef) CM_RETURNS_RETAINED;
CMSampleBufferRef cp_CMSampleBufferCreatePixelBuffer(CVPixelBufferRef pixelBufferRef, CMSampleTimingInfo sampleTiming) CM_RETURNS_RETAINED;

NS_ASSUME_NONNULL_END
