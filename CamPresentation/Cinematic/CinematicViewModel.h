//
//  CinematicViewModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicViewModel : NSObject
- (void)loadWithPHAsset:(PHAsset *)asset;
@end

NS_ASSUME_NONNULL_END
