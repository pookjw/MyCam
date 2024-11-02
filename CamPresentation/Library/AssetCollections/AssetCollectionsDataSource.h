//
//  AssetCollectionsDataSource.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetCollectionsDataSource : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView cellRegistration:(UICollectionViewCellRegistration *)cellRegistration supplementaryRegistration:(UICollectionViewSupplementaryRegistration *)supplementaryRegistration;
- (PHAssetCollection * _Nullable)collectionAtIndexPath:(NSIndexPath *)indexPath;
- (PHAssetCollectionType)collectionTypeOfSectionIndex:(NSInteger)sectionIndex;
@end

NS_ASSUME_NONNULL_END
