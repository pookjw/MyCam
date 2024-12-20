//
//  VNRequest+Category.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/20/24.
//

#import <Vision/Vision.h>

NS_ASSUME_NONNULL_BEGIN

@interface VNRequest (Category)
@property (assign, nonatomic, setter=cp_setProcessAsynchronously:) BOOL cp_processAsynchronously;
@end

NS_ASSUME_NONNULL_END
