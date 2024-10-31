//
//  PhotosViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/31/24.
//

#import <CamPresentation/PhotosViewController.h>
#import <CamPresentation/AssetsViewController.h>

@interface PhotosViewController ()

@end

@implementation PhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemGreenColor;
    
    UIBarButtonItem *fooBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ladybug.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(foo:)];
    self.navigationItem.rightBarButtonItem = fooBarButtonItem;
    [fooBarButtonItem release];
    
    [self foo:nil];
}

- (void)foo:(UIBarButtonItem *)sender {
    PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    AssetsViewController *assetsViewController = [AssetsViewController new];
    [self.navigationController pushViewController:assetsViewController animated:YES];
    assetsViewController.collection = fetchResult.firstObject;
    [assetsViewController release];
}

@end
