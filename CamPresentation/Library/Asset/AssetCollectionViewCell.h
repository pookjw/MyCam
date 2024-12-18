//
//  AssetCollectionViewCell.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/AssetsItemModel.h>
#import <CamPresentation/AssetContentView.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetCollectionViewCell : UICollectionViewCell
@property (nonatomic, readonly) AssetContentView *ownContentView;
@end

NS_ASSUME_NONNULL_END
