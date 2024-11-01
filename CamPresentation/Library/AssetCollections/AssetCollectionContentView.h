//
//  AssetCollectionContentView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetCollectionContentView : UIView
@property (retain, nonatomic, nullable) PHAssetCollection *collection;
@end

NS_ASSUME_NONNULL_END
