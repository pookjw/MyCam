//
//  VisionKitDemoViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/8/25.
//

#import <CamPresentation/VisionKitDemoViewController.h>
#import <VisionKit/VisionKit.h>

@interface VisionKitDemoViewController ()
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *_cellRegistration;
@end

@implementation VisionKitDemoViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:listConfiguration];
    [listConfiguration release];
    
    if (self = [super initWithCollectionViewLayout:collectionViewLayout]) {
        
    }
    
    return self;
}

- (void)dealloc {
    [__cellRegistration release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _cellRegistration];
}

@end
