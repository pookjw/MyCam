//
//  cp_CMSampleBufferCreatePixelBuffer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/5/25.
//

#import <CamPresentation/cp_CMSampleBufferCreatePixelBuffer.h>

CMSampleBufferRef cp_CMSampleBufferCreatePixelBuffer(CVPixelBufferRef pixelBufferRef) {
    CMVideoFormatDescriptionRef desc;
    assert(CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBufferRef, &desc) == kCVReturnSuccess);
    
    CMSampleTimingInfo timing = {
        .duration = kCMTimeZero,
        .presentationTimeStamp = kCMTimeZero,
        .decodeTimeStamp = kCMTimeInvalid
    };
    CMSampleBufferRef sampleBuffer;
    assert(CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, pixelBufferRef, desc, &timing, &sampleBuffer) == kCVReturnSuccess);
    CFRelease(desc);
    
    return sampleBuffer;
}
