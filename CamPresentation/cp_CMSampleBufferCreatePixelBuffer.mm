//
//  cp_CMSampleBufferCreatePixelBuffer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/5/25.
//

#import <CamPresentation/cp_CMSampleBufferCreatePixelBuffer.h>

CMSampleBufferRef cp_CMSampleBufferCreatePixelBuffer(CVPixelBufferRef pixelBufferRef) {
    CMSampleTimingInfo sampleTiming = {
        .duration = kCMTimeZero,
        .presentationTimeStamp = kCMTimeZero,
        .decodeTimeStamp = kCMTimeInvalid
    };
    
    return cp_CMSampleBufferCreatePixelBuffer(pixelBufferRef, sampleTiming);
}

CMSampleBufferRef cp_CMSampleBufferCreatePixelBuffer(CVPixelBufferRef pixelBufferRef, CMSampleTimingInfo sampleTiming) {
    CMVideoFormatDescriptionRef desc;
    assert(CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBufferRef, &desc) == kCVReturnSuccess);
    
    CMSampleBufferRef sampleBuffer;
    assert(CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, pixelBufferRef, desc, &sampleTiming, &sampleBuffer) == kCVReturnSuccess);
    CFRelease(desc);
    
    return sampleBuffer;
}
