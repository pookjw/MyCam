//
//  AssetCollectionsCollectionViewLayoutInvalidationContext.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/5/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetCollectionsCollectionViewLayoutInvalidationContext : UICollectionViewLayoutInvalidationContext
@property (copy, nonatomic, nullable) UICollectionViewLayoutAttributes *preferredAttributes;
@property (copy, nonatomic, nullable) UICollectionViewLayoutAttributes *originalAttributes;
@property (assign, nonatomic) CGRect oldBounds;
@property (assign, nonatomic) CGRect newBounds;
@end

NS_ASSUME_NONNULL_END
