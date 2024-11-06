//
//  AssetCollectionsContentView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/AssetCollectionsItemModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetCollectionsContentView : UIView
@property (retain, nonatomic, nullable) AssetCollectionsItemModel *model;
@end

NS_ASSUME_NONNULL_END
