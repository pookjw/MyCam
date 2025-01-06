//
//  AssetCollectionsViewControllerDelegateResolver.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/6/25.
//

#import <CamPresentation/AssetCollectionsViewControllerDelegateResolver.h>

@implementation AssetCollectionsViewControllerDelegateResolver

- (void)dealloc {
    [_didSelectAssetsHandler release];
    [super dealloc];
}

- (void)assetCollectionsViewController:(AssetCollectionsViewController *)assetCollectionsViewController didSelectAssets:(NSSet<PHAsset *> *)selectedAssets {
    if (auto didSelectAssetsHandler = self.didSelectAssetsHandler) {
        didSelectAssetsHandler(assetCollectionsViewController, selectedAssets);
    }
}

@end
