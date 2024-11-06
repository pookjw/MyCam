//
//  AssetContentView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/AssetsItemModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetContentView : UIView
@property (retain, nonatomic, nullable) AssetsItemModel *model;
- (void)didChangeIsDisplaying:(BOOL)isDisplaying;
@end

NS_ASSUME_NONNULL_END
