//
//  AssetContentView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <CamPresentation/AssetItemModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetContentView : UIView
@property (retain, nonatomic, nullable) AssetItemModel *model;
@end

NS_ASSUME_NONNULL_END
