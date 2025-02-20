//
//  AssetsDataSource.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetsDataSource.h>
#import <CamPresentation/AssetsItemModel.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AssetsDataSource () <UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, PHPhotoLibraryAvailabilityObserver, PHPhotoLibraryChangeObserver>
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *cellRegistration;
@property (assign, nonatomic, readonly) BOOL requestMaximumSize;
@property (retain, nonatomic, readonly) PHPhotoLibrary *photoLibrary;
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@property (retain, nonatomic, nullable) PHFetchResult<PHAsset *> *mainQueue_assetsFetchResult;
@property (retain, nonatomic, readonly) NSMutableDictionary<NSIndexPath *, AssetsItemModel *> *prefetchingModelsByIndexPath;
@end

@implementation AssetsDataSource

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView cellRegistration:(UICollectionViewCellRegistration *)cellRegistration requestMaximumSize:(BOOL)requestMaximumSize {
    if (self = [super init]) {
        assert(collectionView.dataSource == nil);
        assert(collectionView.prefetchDataSource == nil);
        
        collectionView.dataSource = self;
        collectionView.prefetchDataSource = self;
        
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t queue = dispatch_queue_create("Assets Data Source Queue", attr);
        
        _collectionView = [collectionView retain];
        _cellRegistration = [cellRegistration retain];
        _requestMaximumSize = requestMaximumSize;
        _queue = queue;
        
        PHPhotoLibrary *photoLibrary = PHPhotoLibrary.sharedPhotoLibrary;
        assert(photoLibrary.unavailabilityReason == nil);
        [photoLibrary registerChangeObserver:self];
        [photoLibrary registerAvailabilityObserver:self];
        _photoLibrary = [photoLibrary retain];
        
        _prefetchingModelsByIndexPath = [NSMutableDictionary<NSIndexPath *, AssetsItemModel *> new];
    }
    
    return self;
}

- (void)dealloc {
    dispatch_release(_queue);
    [_collectionView release];
    [_cellRegistration release];
    [_photoLibrary unregisterChangeObserver:self];
    [_photoLibrary unregisterAvailabilityObserver:self];
    [_photoLibrary release];
    [_mainQueue_assetsFetchResult release];
    [_prefetchingModelsByIndexPath release];
    [super dealloc];
}

- (void)updateCollection:(PHAssetCollection *)collection completionHandler:(void (^ _Nullable)(void))completionHandler {
    dispatch_async(self.queue, ^{
        PHFetchOptions *options = [PHFetchOptions new];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setReverseSortOrder:"), YES);
        options.wantsIncrementalChangeDetails = YES; // NO로 하면?
        options.includeHiddenAssets = NO;
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setPhotoLibrary:"), self.photoLibrary);
        
        PHFetchResult<PHAsset *> *assetsFetchResult;
        if (collection == nil) {
            assetsFetchResult = [PHAsset fetchAssetsWithOptions:options];
        } else {
            assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        }
        [options release];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.mainQueue_assetsFetchResult = assetsFetchResult;
            [self.collectionView reloadData];
            
            if (completionHandler) completionHandler();
        });
    });
}

- (PHAsset *)assetAtIndexPath:(NSIndexPath *)indexPath {
    dispatch_assert_queue(dispatch_get_main_queue());
    return self.mainQueue_assetsFetchResult[indexPath.item];
}

- (NSIndexPath *)indexPathFromAsset:(PHAsset *)asset {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    __block NSInteger index = NSNotFound;
    
    [self.mainQueue_assetsFetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqual:asset]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    return [NSIndexPath indexPathForItem:index inSection:0];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.mainQueue_assetsFetchResult.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AssetsItemModel *model = [self.prefetchingModelsByIndexPath[indexPath] retain];
    
    if (model == nil) {
        PHAsset *asset = self.mainQueue_assetsFetchResult[indexPath.item];
        model = [[AssetsItemModel alloc] initWithAsset:asset];
    } else {
        [self.prefetchingModelsByIndexPath removeObjectForKey:indexPath];
    }
    
    __kindof UICollectionViewCell *cell = [collectionView dequeueConfiguredReusableCellWithRegistration:self.cellRegistration forIndexPath:indexPath item:model];
    [model release];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    __kindof UICollectionViewCell * _Nullable firstVisibleCell = collectionView.visibleCells.firstObject;
    if (firstVisibleCell == nil) return;
    
    PHFetchResult<PHAsset *> *assetsFetchResult = self.mainQueue_assetsFetchResult;
    CGSize targetSize;
    if (self.requestMaximumSize) {
        targetSize = PHImageManagerMaximumSize;
    } else {
        targetSize = firstVisibleCell.bounds.size;
        CGFloat displayScale = reinterpret_cast<CGFloat (*)(id, SEL)>(objc_msgSend)(firstVisibleCell, sel_registerName("_currentScreenScale"));
        targetSize.width *= displayScale;
        targetSize.height *= displayScale;
    }
    
    NSMutableDictionary<NSIndexPath *, AssetsItemModel *> *prefetchingModelsByIndexPath = self.prefetchingModelsByIndexPath;
    
    for (NSIndexPath *indexPath in indexPaths) {
        assert(prefetchingModelsByIndexPath[indexPath] == nil);
        
        AssetsItemModel *model = [[AssetsItemModel alloc] initWithAsset:assetsFetchResult[indexPath.item]];
        prefetchingModelsByIndexPath[indexPath] = model;
        
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.synchronous = NO;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        options.networkAccessAllowed = YES;
        options.allowSecondaryDegradedImage = YES;
        
        if (self.requestMaximumSize) {
            options.resizeMode = PHImageRequestOptionsResizeModeNone;
        } else {
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
        }
        
        [model requestImageWithTargetSize:targetSize options:options resultHandler:nil];
        [options release];
        [model release];
    }
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableDictionary<NSIndexPath *, AssetsItemModel *> *prefetchingModelsByIndexPath = self.prefetchingModelsByIndexPath;
    
    for (NSIndexPath *indexPath in indexPaths) {
        AssetsItemModel *model = prefetchingModelsByIndexPath[indexPath];
//        assert(model != nil);
        [model cancelRequest];
        [prefetchingModelsByIndexPath removeObjectForKey:indexPath];
    }
}

- (void)photoLibraryDidBecomeUnavailable:(PHPhotoLibrary *)photoLibrary {
    abort();
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(self.queue, ^{
        __block PHFetchResult<PHAsset *> * _Nullable assetsFetchResult;
        dispatch_sync(dispatch_get_main_queue(), ^{
            assetsFetchResult = self.mainQueue_assetsFetchResult;
        });
        
        if (assetsFetchResult == nil) return;
        
        PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:assetsFetchResult];
        if (!changeDetails.hasIncrementalChanges) return;
        
        PHFetchResult<PHAsset *> *fetchResultAfterChanges = changeDetails.fetchResultAfterChanges;
        
        NSIndexSet *removedIndexes = changeDetails.removedIndexes;
        NSMutableArray<NSIndexPath *> *removedIndexPaths = [[NSMutableArray alloc] initWithCapacity:removedIndexes.count];
        [removedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
            [removedIndexPaths addObject:indexPath];
        }];
        
        NSIndexSet *insertedIndexes = changeDetails.insertedIndexes;
        NSMutableArray<NSIndexPath *> *insertedIndexPaths = [[NSMutableArray alloc] initWithCapacity:insertedIndexes.count];
        [insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
            [insertedIndexPaths addObject:indexPath];
        }];
        
        NSIndexSet *changedIndexes = changeDetails.changedIndexes;
        NSMutableArray<NSIndexPath *> *changedIndexPaths = [[NSMutableArray alloc] initWithCapacity:changedIndexes.count];
        [changedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
            [changedIndexPaths addObject:indexPath];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UICollectionView *collectionView = self.collectionView;
            
            [collectionView performBatchUpdates:^{
                self.mainQueue_assetsFetchResult = fetchResultAfterChanges;
                [collectionView deleteItemsAtIndexPaths:removedIndexPaths];
                [collectionView insertItemsAtIndexPaths:insertedIndexPaths];
                [collectionView reconfigureItemsAtIndexPaths:changedIndexPaths];
            }
                                          completion:nil];
        });
        
        [removedIndexPaths release];
        [insertedIndexPaths release];
        [changedIndexPaths release];
    });
}

@end
