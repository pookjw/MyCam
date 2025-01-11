//
//  ImageFiltersViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/10/25.
//

#import <CamPresentation/ImageFiltersViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CoreImage/CoreImage.h>
#import <CamPresentation/ImageFilterDescriptor.h>

@interface ImageFiltersViewController ()
@property (retain, nonatomic, readonly, getter=_collectionView) UICollectionView *collectionView;
@property (retain, nonatomic, readonly, getter=_dataSource) UICollectionViewDiffableDataSource<NSNull *, NSString *> *dataSource;
@property (retain, nonatomic, readonly, getter=_cellRegistration) UICollectionViewCellRegistration *cellRegistration;
@property (retain, nonatomic, readonly, getter=_tmpBarButtonItem) UIBarButtonItem *tmpBarButtonItem;
@end

@implementation ImageFiltersViewController
@synthesize collectionView = _collectionView;
@synthesize dataSource = _dataSource;
@synthesize cellRegistration = _cellRegistration;
@synthesize tmpBarButtonItem = _tmpBarButtonItem;

- (void)dealloc {
    [_collectionView release];
    [_dataSource release];
    [_cellRegistration release];
    [_tmpBarButtonItem release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDiffableDataSourceSectionSnapshot<NSString *> *snapshot = [NSDiffableDataSourceSectionSnapshot new];
    
    NSArray<NSString *> *allCategories = reinterpret_cast<id (*)(id, SEL, BOOL)>(objc_msgSend)([CIFilter class], sel_registerName("allCategories:"), YES);
    [snapshot appendItems:allCategories];
    
    for (NSString *category in allCategories) {
        NSArray<NSString *> *filterNames = [CIFilter filterNamesInCategory:category];
        [snapshot appendItems:filterNames intoParentItem:category];
    }
    
    [self.dataSource applySnapshot:snapshot toSection:[NSNull null] animatingDifferences:YES];
    [snapshot release];
    
    self.navigationItem.rightBarButtonItem = self.tmpBarButtonItem;
}

- (UICollectionView *)_collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:listConfiguration];
    [listConfiguration release];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    
    _collectionView = collectionView;
    return collectionView;
}

- (UICollectionViewDiffableDataSource<NSNull * ,NSString *> *)_dataSource {
    if (auto dataSource = _dataSource) return dataSource;
    
    UICollectionViewCellRegistration *cellRegistration = self.cellRegistration;
    
    UICollectionViewDiffableDataSource<NSNull * ,NSString *> *dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, id  _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    _dataSource = dataSource;
    return dataSource;
}

- (UICollectionViewCellRegistration *)_cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    NSArray<NSString *> *allCategories = reinterpret_cast<id (*)(id, SEL, BOOL)>(objc_msgSend)([CIFilter class], sel_registerName("allCategories:"), YES);
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:[UICollectionViewListCell class] configurationHandler:^(UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, NSString * _Nonnull item) {
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        
        NSString *text;
        UIColor * _Nullable textColor;
        NSArray<UICellAccessory *> *accessories;
        
        if ([allCategories containsObject:item]) {
            text = item;
            textColor = nil;
            
            UICellAccessoryOutlineDisclosure *outlineDisclosure = [UICellAccessoryOutlineDisclosure new];
            outlineDisclosure.style = UICellAccessoryOutlineDisclosureStyleHeader;
            accessories = @[outlineDisclosure];
            [outlineDisclosure release];
        } else {
            ImageFilterDescriptor * _Nullable descriptor = [[ImageFilterDescriptor alloc] initWithFilterName:item];
            if (descriptor == nil) {
                text = [NSString stringWithFormat:@"%@ (Unimplemented)", item];
                textColor = UIColor.systemRedColor;
            } else {
                text = item;
                textColor = nil;
                [descriptor release];
            }
            
            accessories = @[];
        }
        
        contentConfiguration.text = text;
        
        if (textColor) {
            contentConfiguration.textProperties.color = textColor;
        }
        
        cell.contentConfiguration = contentConfiguration;
        
        cell.accessories = accessories;
    }];
    
    _cellRegistration = [cellRegistration retain];
    return cellRegistration;
}

- (UIBarButtonItem *)_tmpBarButtonItem {
    if (auto tmpBarButtonItem = _tmpBarButtonItem) return tmpBarButtonItem;
    
    UIBarButtonItem *tmpBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"TMP" style:UIBarButtonItemStylePlain target:self action:@selector(_didTriggerTmpBarButtonItem:)];
    
    _tmpBarButtonItem = tmpBarButtonItem;
    return tmpBarButtonItem;
}

- (void)_didTriggerTmpBarButtonItem:(UIBarButtonItem *)sender {
    id _diffableDataSourceImpl = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self.dataSource, sel_registerName("_diffableDataSourceImpl"));
    NSArray *sectionControllers = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(_diffableDataSourceImpl, sel_registerName("sectionControllers"));
    
    reinterpret_cast<void (*)(id, SEL, NSUInteger, id)>(objc_msgSend)(sectionControllers[0], sel_registerName("_performDisclosureAction:forItem:"), 1, @"CICategoryBlur");
}

@end
