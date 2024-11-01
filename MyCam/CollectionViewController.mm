//
//  CollectionViewController.mm
//  MyCam
//
//  Created by Jinwoo Kim on 10/31/24.
//

#import "CollectionViewController.h"
#import <CamPresentation/CamPresentation.h>
#import <TargetConditionals.h>

@interface CollectionViewController ()
@property (class, nonatomic, readonly) NSArray<Class> *viewControllerClasses;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *cellRegistration;
@end

@implementation CollectionViewController
@synthesize cellRegistration = _cellRegistration;

+ (NSArray<Class> *)viewControllerClasses {
    return @[
#if !TARGET_OS_VISION
        CameraRootViewController.class,
#endif
        CollectionsViewController.class
    ];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:listConfiguration];
    [listConfiguration release];
    
    if (self = [super initWithCollectionViewLayout:collectionViewLayout]) {
        
    }
    
    return self;
}

- (void)dealloc {
    [_cellRegistration release];
    [super dealloc];
}

- (UICollectionViewCellRegistration *)cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    NSArray<Class> *viewControllerClasses = CollectionViewController.viewControllerClasses;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, id  _Nonnull item) {
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        contentConfiguration.text = NSStringFromClass(viewControllerClasses[indexPath.item]);
        cell.contentConfiguration = contentConfiguration;
        
        UICellAccessoryDisclosureIndicator *accessory = [UICellAccessoryDisclosureIndicator new];
        cell.accessories = @[accessory];
        [accessory release];
    }];
    
    _cellRegistration = [cellRegistration retain];
    return cellRegistration;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self cellRegistration];
    
    CollectionsViewController *photosViewController = [CollectionsViewController new];
    [self.navigationController pushViewController:photosViewController animated:YES];
    [photosViewController release];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return CollectionViewController.viewControllerClasses.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueConfiguredReusableCellWithRegistration:self.cellRegistration forIndexPath:indexPath item:[NSNull null]];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    __kindof UIViewController *viewController = [CollectionViewController.viewControllerClasses[indexPath.item] new];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

@end
