//
//  AssetsViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetsViewController.h>
#import <CamPresentation/AssetsDataSource.h>
#import <CamPresentation/AssetsCollectionViewCell.h>
#import <CamPresentation/AssetsItemModel.h>
#import <CamPresentation/AssetsCollectionViewLayout.h>
#import <CamPresentation/AssetViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */

@interface AssetsViewController () <UICollectionViewDelegate, AssetViewControllerDelegate>
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) UIBarButtonItem *cancelBarButton;
@property (retain, nonatomic, readonly) AssetsDataSource *dataSource;
@end

@implementation AssetsViewController
@synthesize collectionView = _collectionView;
@synthesize cancelBarButton = _cancelBarButton;
@synthesize dataSource = _dataSource;

- (void)dealloc {
    [_collection release];
    [_collectionView release];
    [_cancelBarButton release];
    [_dataSource release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[
        self.editButtonItem
    ];
    
    [self editingDidChange];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.collectionView.allowsMultipleSelection) {
        reinterpret_cast<void (*)(id, SEL, id, BOOL, id)>(objc_msgSend)(self.collectionView, sel_registerName("_deselectItemsAtIndexPaths:animated:transitionCoordinator:"), self.collectionView.indexPathsForSelectedItems, animated, self.transitionCoordinator);
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self editingDidChange];
}

- (void)setCollection:(PHAssetCollection *)collection {
    if ([_collection isEqual:collection]) return;
    
    _collection = [collection retain];
    [self.dataSource updateCollection:collection completionHandler:nil];
}

- (void)editingDidChange {
    BOOL editing = self.editing;
    
    if (!editing) {
        auto delegate = self.delegate;
        
        if (delegate != nil) {
            NSArray<NSIndexPath *> *indexPathsForSelectedItems = self.collectionView.indexPathsForSelectedItems;
            
            if (indexPathsForSelectedItems.count != 0) {
                NSMutableArray<PHAsset *> *phAssets = [[NSMutableArray alloc] initWithCapacity:indexPathsForSelectedItems.count];
                for (NSIndexPath *indexPath in indexPathsForSelectedItems) {
                    PHAsset *phAsset = [self.dataSource assetAtIndexPath:indexPath];
                    assert(phAsset != nil);
                    [phAssets addObject:phAsset];
                }
                [delegate assetsViewController:self didSelectAssets:phAssets];
                [phAssets release];
            }
        }
    }
    
    self.collectionView.editing = editing;
    
    if (editing) {
        self.navigationItem.leftBarButtonItems = @[
            self.cancelBarButton
        ];
        self.navigationItem.hidesBackButton = YES;
    } else {
        self.navigationItem.leftBarButtonItems = @[];
        self.navigationItem.hidesBackButton = NO;
    }
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    AssetsCollectionViewLayout *collectionViewLayout = [AssetsCollectionViewLayout new];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    
    collectionView.allowsMultipleSelectionDuringEditing = YES;
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (UIBarButtonItem *)cancelBarButton {
    if (auto cancelBarButton = _cancelBarButton) return cancelBarButton;
    
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Cacnel" image:[UIImage systemImageNamed:@"xmark"] target:self action:@selector(cancelBarButtonDidTrigger:) menu:nil];
    
    _cancelBarButton = cancelBarButton;
    return cancelBarButton;
}

- (AssetsDataSource *)dataSource {
    if (auto dataSource = _dataSource) return dataSource;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:AssetsCollectionViewCell.class configurationHandler:^(AssetsCollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, AssetsItemModel * _Nonnull model) {
        cell.model = model;
    }];
    
    AssetsDataSource *dataSource = [[AssetsDataSource alloc] initWithCollectionView:self.collectionView cellRegistration:cellRegistration requestMaximumSize:NO];
    
    _dataSource = [dataSource retain];
    return [dataSource autorelease];
}

- (void)cancelBarButtonDidTrigger:(UIBarButtonItem *)sender {
    [self.collectionView selectItemAtIndexPath:nil animated:YES scrollPosition:0];
    self.editing = NO;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) return;
    
    PHAssetCollection *collection = self.collection;
    PHAsset *asset = [self.dataSource assetAtIndexPath:indexPath];
    assert(asset != nil);
    
    AssetViewController *assetViewController = [[AssetViewController alloc] initWithCollection:collection asset:asset];
    assetViewController.delegate = self;
    [self.navigationController pushViewController:assetViewController animated:YES];
    [assetViewController release];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    
}
- (void)collectionViewDidEndMultipleSelectionInteraction:(UICollectionView *)collectionView {
    
}

- (void)assetViewController:(AssetViewController *)assetViewController didSelectAsset:(PHAsset *)selectedAsset {
    if (id<AssetsViewControllerDelegate> delegate = self.delegate) {
        [delegate assetsViewController:self didSelectAssets:@[selectedAsset]];
    }
}

@end
