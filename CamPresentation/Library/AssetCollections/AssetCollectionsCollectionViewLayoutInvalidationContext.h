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
@end

NS_ASSUME_NONNULL_END
