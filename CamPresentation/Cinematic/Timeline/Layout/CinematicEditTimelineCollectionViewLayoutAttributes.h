//
//  CinematicEditTimelineCollectionViewLayoutAttributes.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import <Cinematic/Cinematic.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface CinematicEditTimelineCollectionViewLayoutAttributes : UICollectionViewLayoutAttributes
@property (assign, nonatomic) CMTime thumbnailPresentationTime;
@property (assign, nonatomic) CMPersistentTrackID thumbnailPresentationTrackID;
@property (assign, nonatomic) CNDetectionID thumbnailPresentationDetectionTrackID;
@end

NS_ASSUME_NONNULL_END
