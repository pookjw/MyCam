//
//  AssetsContentView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/AssetsItemModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetsContentView : UIView
@property (retain, nonatomic, nullable) AssetsItemModel *model;
@end

NS_ASSUME_NONNULL_END