//
//  AssetCollectionCell.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/AssetCollectionItemModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetCollectionCell : UICollectionViewCell
@property (retain, nonatomic, nullable) AssetCollectionItemModel *model;
@end

NS_ASSUME_NONNULL_END
