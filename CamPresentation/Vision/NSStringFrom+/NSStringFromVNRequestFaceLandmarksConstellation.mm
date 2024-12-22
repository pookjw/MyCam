//
//  NSStringFromVNRequestFaceLandmarksConstellation.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <CamPresentation/NSStringFromVNRequestFaceLandmarksConstellation.h>

NSString * NSStringFromVNRequestFaceLandmarksConstellation(VNRequestFaceLandmarksConstellation constellation) {
    switch (constellation) {
        case VNRequestFaceLandmarksConstellationNotDefined:
            return @"Not Defined";
        case VNRequestFaceLandmarksConstellation65Points:
            return @"65 Points";
        case VNRequestFaceLandmarksConstellation76Points:
            return @"76 Points";
        default:
            abort();
    }
}
