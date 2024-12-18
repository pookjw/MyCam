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
@property (retain, nonatomic, readonly, nullable) AssetsItemModel *model;
- (void)didChangeIsDisplaying:(BOOL)isDisplaying;
- (void)setModel:(AssetsItemModel * _Nullable)model imageHandler:(void (^ _Nullable)(UIImage * _Nullable image, BOOL isDegraded))imageHandler;
@end

NS_ASSUME_NONNULL_END
