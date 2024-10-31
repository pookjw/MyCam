//
//  AssetContentView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetContentView : UIView
@property (retain, nonatomic, nullable) PHAsset *asset;
@end

NS_ASSUME_NONNULL_END
