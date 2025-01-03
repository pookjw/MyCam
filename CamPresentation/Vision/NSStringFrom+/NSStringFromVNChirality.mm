//
//  NSStringFromVNChirality.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/3/25.
//

#import <CamPresentation/NSStringFromVNChirality.h>

NSString * NSStringFromVNChirality(VNChirality chirality) {
    switch (chirality) {
        case VNChiralityLeft:
            return @"Left";
        case VNChiralityRight:
            return @"Right";
        case VNChiralityUnknown:
            return @"Unknown";
        default:
            abort();
    }
}
