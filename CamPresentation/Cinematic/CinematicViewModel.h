//
//  CinematicViewModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <Photos/Photos.h>
#import <Cinematic/Cinematic.h>
#import <CamPresentation/Extern.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSString * CinematicViewModelErrorKey;

@interface CinematicViewModel : NSObject
+ (NSProgress *)loadCNAssetInfoFromPHAsset:(PHAsset *)phAsset completionHandler:(void (^)(CNAssetInfo * _Nullable cinematicAssetInfo, NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
