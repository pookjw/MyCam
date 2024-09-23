//
//  NSStringFromCMVideoDimensions.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/18/24.
//

#import <CamPresentation/NSStringFromCMVideoDimensions.h>

NSString * NSStringFromCMVideoDimensions(CMVideoDimensions videoDimensions) {
    return [NSString stringWithFormat:@"{%d, %d}", videoDimensions.width, videoDimensions.height];
}
