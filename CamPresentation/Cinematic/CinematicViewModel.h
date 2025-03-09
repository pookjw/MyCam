//
//  CinematicViewModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <Photos/Photos.h>
#import <Cinematic/Cinematic.h>
#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <CamPresentation/CinematicAssetData.h>
#import <CamPresentation/CinematicCompositions.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicViewModel : NSObject
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@property (retain, nonatomic, readonly, nullable) CinematicCompositions *isolated_compositions;
- (void)isolated_loadWithData:(CinematicAssetData *)data;
@end

NS_ASSUME_NONNULL_END
