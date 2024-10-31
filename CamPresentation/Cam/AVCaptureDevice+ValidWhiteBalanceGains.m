//
//  AVCaptureDevice+ValidWhiteBalanceGains.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/26/24.
//

#import <CamPresentation/AVCaptureDevice+ValidWhiteBalanceGains.h>

@implementation AVCaptureDevice (ValidWhiteBalanceGains)

- (BOOL)cp_isValidWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains {
    float maxWhiteBalanceGain = self.maxWhiteBalanceGain;
    
    if ((gains.redGain < 1.f) || (gains.redGain > maxWhiteBalanceGain) || (gains.greenGain < 1.f) || (gains.greenGain > maxWhiteBalanceGain) || (gains.blueGain < 1.f) || (gains.blueGain > maxWhiteBalanceGain)) {
        return NO;
    }
    
    return YES;
}

@end
