//
//  CinematicViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicViewController.h>
#import <CamPresentation/AssetCollectionsViewController.h>
#import <Cinematic/Cinematic.h>

@interface CinematicViewController () <AssetCollectionsViewControllerDelegate>
@property (retain, nonatomic, readonly, getter=_assetPickerBarButtonItem) UIBarButtonItem *assetPickerBarButtonItem;
@property (retain, nonatomic, readonly, getter=_assetPickerViewController) AssetCollectionsViewController *assetPickerViewController;
@end

@implementation CinematicViewController
@synthesize assetPickerBarButtonItem = _assetPickerBarButtonItem;
@synthesize assetPickerViewController = _assetPickerViewController;

- (void)dealloc {
    [_assetPickerBarButtonItem release];
    [_assetPickerViewController release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.style = UINavigationItemStyleEditor;
    navigationItem.trailingItemGroups = @[
        [UIBarButtonItemGroup fixedGroupWithRepresentativeItem:nil items:@[
            self.assetPickerBarButtonItem
        ]]
    ];
    
    {
        PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[@"80BF37FF-7827-4B49-B6DF-3A0CC9C5D5ED/L0/001"] options:nil];
        [self _loadWithPHAsset:assets[0]];
    }
}

- (UIBarButtonItem *)_assetPickerBarButtonItem {
    if (auto assetPickerBarButtonItem = _assetPickerBarButtonItem) return assetPickerBarButtonItem;
    
    UIBarButtonItem *assetPickerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"photo"] style:UIBarButtonItemStylePlain target:self action:@selector(_didTriggerAssetPickerBarButtonItem:)];
    
    _assetPickerBarButtonItem = assetPickerBarButtonItem;
    return assetPickerBarButtonItem;
}

- (AssetCollectionsViewController *)_assetPickerViewController {
    if (auto assetPickerViewController = _assetPickerViewController) return assetPickerViewController;
    
    AssetCollectionsViewController *assetPickerViewController = [AssetCollectionsViewController new];
    assetPickerViewController.delegate = self;
    
    _assetPickerViewController = assetPickerViewController;
    return assetPickerViewController;
}

- (void)_didTriggerAssetPickerBarButtonItem:(UIBarButtonItem *)sender {
    AssetCollectionsViewController *assetPickerViewController = self.assetPickerViewController;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:assetPickerViewController];
    [assetPickerViewController release];
    
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    navigationController.popoverPresentationController.sourceItem = sender;
    
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
}

- (void)assetCollectionsViewController:(AssetCollectionsViewController *)assetCollectionsViewController didSelectAssets:(NSSet<PHAsset *> *)selectedAssets {
    if (PHAsset *asset = selectedAssets.allObjects.firstObject) {
        [self _loadWithPHAsset:asset];
    }
}

- (void)_loadWithPHAsset:(PHAsset *)asset {
    assert(asset.mediaType == PHAssetMediaTypeVideo);
    assert((asset.mediaSubtypes & PHAssetMediaSubtypeVideoCinematic) != 0);
    
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    
    [PHImageManager.defaultManager requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        assert(asset != nil);
        
        if (auto isDegradedNumber = static_cast<NSNumber *>(info[PHImageResultIsDegradedKey])) {
            if (isDegradedNumber.boolValue) return;
        }
        
        [CNAssetInfo loadFromAsset:asset completionHandler:^(CNAssetInfo * _Nullable cinematicAssetInfo, NSError * _Nullable error) {
            assert(error == nil);
            NSLog(@"%@", cinematicAssetInfo);
            NSLog(@"%@", cinematicAssetInfo.allCinematicTracks);
        }];
    }];
    
    [options release];
}

@end
