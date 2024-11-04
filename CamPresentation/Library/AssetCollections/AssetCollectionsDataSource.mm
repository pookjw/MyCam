//
//  AssetCollectionsDataSource.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetCollectionsDataSource.h>
#import <CamPresentation/AssetCollectionItemModel.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <vector>
#include <ranges>
#include <algorithm>
#include <iterator>

@interface AssetCollectionsDataSource () <UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, PHPhotoLibraryAvailabilityObserver, PHPhotoLibraryChangeObserver>
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *cellRegistration;
@property (retain, nonatomic, readonly) UICollectionViewSupplementaryRegistration *supplementaryRegistration;
@property (retain, nonatomic, readonly) PHPhotoLibrary *photoLibrary;
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@property (retain, nonatomic, nullable, setter=mainQueue_setFetchResultsByCollectionType:) NSMutableDictionary<NSNumber *, PHFetchResult<PHAssetCollection *> *> *mainQueue_fetchResultsByCollectionType;
@property (retain, nonatomic, readonly) NSMutableDictionary<NSIndexPath *, AssetCollectionItemModel *> *prefetchingModelsByIndexPath;
@property (nonatomic, readonly) std::vector<PHAssetCollectionType> allCollectionTypesSet;
@end

@implementation AssetCollectionsDataSource
@synthesize mainQueue_fetchResultsByCollectionType = _mainQueue_fetchResultsByCollectionType;

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView cellRegistration:(UICollectionViewCellRegistration *)cellRegistration supplementaryRegistration:(UICollectionViewSupplementaryRegistration *)supplementaryRegistration {
    if (self = [super init]) {
        assert(collectionView.dataSource == nil);
        assert(collectionView.prefetchDataSource == nil);
        
        collectionView.dataSource = self;
//        collectionView.prefetchDataSource = self;
        
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t queue = dispatch_queue_create("Collections Data Source Queue", attr);
        
        _collectionView = [collectionView retain];
        _cellRegistration = [cellRegistration retain];
        _supplementaryRegistration = [supplementaryRegistration retain];
        _queue = queue;
        
        PHPhotoLibrary *photoLibrary = PHPhotoLibrary.sharedPhotoLibrary;
        assert(photoLibrary.unavailabilityReason == nil);
        [photoLibrary registerAvailabilityObserver:self];
        _photoLibrary = [photoLibrary retain];
        
        _prefetchingModelsByIndexPath = [NSMutableDictionary new];
        
        dispatch_async(queue, ^{
            [photoLibrary registerChangeObserver:self];
            
            PHFetchOptions *options = [PHFetchOptions new];
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setReverseSortOrder:"), YES);
            options.wantsIncrementalChangeDetails = YES; // NO로 하면?
            options.includeHiddenAssets = NO;
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setPhotoLibrary:"), photoLibrary);
            
            auto allCollectionTypesSet = self.allCollectionTypesSet;
            
            NSMutableDictionary<NSNumber *, PHFetchResult<PHAssetCollection *> *> *fetchResultsByCollectionType = [NSMutableDictionary new];
            
            std::ranges::for_each(allCollectionTypesSet, [options, fetchResultsByCollectionType](PHAssetCollectionType type) {
                PHFetchResult<PHAssetCollection *> *albumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:type subtype:PHAssetCollectionSubtypeAny options:options];
                
                // diff에서 0개 -> 1개 및 1개 -> 0개 될 때 Section Insert/Delete 처리가 까다로워, 항상 Section은 존재하게
//                if (albumsFetchResult.count == 0) return;
                
                fetchResultsByCollectionType[@(type)] = albumsFetchResult;
            });
            
            [options release];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.mainQueue_fetchResultsByCollectionType = fetchResultsByCollectionType;
                [collectionView reloadData];
            });
            
            [fetchResultsByCollectionType release];
        });
    }
    
    return self;
}

- (void)dealloc {
    dispatch_release(_queue);
    [_collectionView release];
    [_cellRegistration release];
    [_supplementaryRegistration release];
    [_photoLibrary unregisterChangeObserver:self];
    [_photoLibrary unregisterAvailabilityObserver:self];
    [_photoLibrary release];
    [_mainQueue_fetchResultsByCollectionType release];
    [_prefetchingModelsByIndexPath release];
    [super dealloc];
}

- (PHAssetCollection *)collectionAtIndexPath:(NSIndexPath *)indexPath {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    PHAssetCollectionType collectionType = [self collectionTypeOfSectionIndex:indexPath.section];
    PHFetchResult<PHAssetCollection *> *collectionsFetchResult = self.mainQueue_fetchResultsByCollectionType[@(collectionType)];
    assert(collectionsFetchResult != nil);
    PHAssetCollection *collection = collectionsFetchResult[indexPath.item];
    
    return collection;
}

- (std::vector<PHAssetCollectionType>)allCollectionTypesSet {
    return {
        PHAssetCollectionTypeSmartAlbum,
        PHAssetCollectionTypeAlbum
    };
}

- (NSMutableDictionary<NSNumber *,PHFetchResult<PHAssetCollection *> *> *)mainQueue_fetchResultsByCollectionType {
    dispatch_assert_queue(dispatch_get_main_queue());
    return [[_mainQueue_fetchResultsByCollectionType retain] autorelease];
}

- (void)mainQueue_setFetchResultsByCollectionType:(NSMutableDictionary<NSNumber *,PHFetchResult<PHAssetCollection *> *> *)mainQueue_fetchResultsByCollectionType {
    dispatch_assert_queue(dispatch_get_main_queue());
    [_mainQueue_fetchResultsByCollectionType release];
    _mainQueue_fetchResultsByCollectionType = [mainQueue_fetchResultsByCollectionType retain];
}

- (NSInteger)sectionIndexOfCollectionType:(PHAssetCollectionType)collectionType {
    dispatch_assert_queue(dispatch_get_main_queue());
    return [self _sectionIndexOfCollectionType:collectionType fetchResultsByCollectionType:self.mainQueue_fetchResultsByCollectionType];
}

- (NSInteger)_sectionIndexOfCollectionType:(PHAssetCollectionType)collectionType fetchResultsByCollectionType:(NSDictionary<NSNumber *, PHFetchResult<PHAssetCollection *> *> *)fetchResultsByCollectionType {
    auto allCollectionTypesFilteredVector = self.allCollectionTypesSet
    | std::views::filter([fetchResultsByCollectionType](PHAssetCollectionType collectionType) -> BOOL {
        return [fetchResultsByCollectionType.allKeys containsObject:@(collectionType)];
    });
    
    auto iterator = std::find(allCollectionTypesFilteredVector.begin(), allCollectionTypesFilteredVector.end(), collectionType);
    
    if (iterator == allCollectionTypesFilteredVector.end()) {
        return NSNotFound;
    } else {
        auto index = std::distance(allCollectionTypesFilteredVector.begin(), iterator);
        return index;
    }
}

- (PHAssetCollectionType)collectionTypeOfSectionIndex:(NSInteger)sectionIndex {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    NSMutableDictionary<NSNumber *, PHFetchResult<PHAssetCollection *> *> *fetchResultsByCollectionType = self.mainQueue_fetchResultsByCollectionType;
    
    auto allCollectionTypesFilteredVector = self.allCollectionTypesSet
    | std::views::filter([fetchResultsByCollectionType](PHAssetCollectionType collectionType) -> BOOL {
        return [fetchResultsByCollectionType.allKeys containsObject:@(collectionType)];
    })
    | std::ranges::to<std::vector<PHAssetCollectionType>>();
    
    return allCollectionTypesFilteredVector[sectionIndex];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.mainQueue_fetchResultsByCollectionType.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    PHAssetCollectionType collectionType = [self collectionTypeOfSectionIndex:section];
    PHFetchResult<PHAssetCollection *> *collectionsFetchResult = self.mainQueue_fetchResultsByCollectionType[@(collectionType)];
    assert(collectionsFetchResult != nil);
    return collectionsFetchResult.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAssetCollection *collection = [self collectionAtIndexPath:indexPath];
    assert(collection != nil);
    AssetCollectionItemModel *model = [self.prefetchingModelsByIndexPath[indexPath] retain];
    if (model == nil) {
        model = [[AssetCollectionItemModel alloc] initWithCollection:collection];
    } else {
        [self.prefetchingModelsByIndexPath removeObjectForKey:indexPath];
    }
    
    __kindof UICollectionViewCell *cell = [collectionView dequeueConfiguredReusableCellWithRegistration:_cellRegistration forIndexPath:indexPath item:model];
    [model release];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueConfiguredReusableSupplementaryViewWithRegistration:_supplementaryRegistration forIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    __kindof UICollectionViewCell * _Nullable firstVisibleCell = collectionView.visibleCells.firstObject;
    if (firstVisibleCell == nil) return;
    
    CGSize targetSize = firstVisibleCell.bounds.size;
    CGFloat displayScale = reinterpret_cast<CGFloat (*)(id, SEL)>(objc_msgSend)(firstVisibleCell, sel_registerName("_currentScreenScale"));
    targetSize.width *= displayScale;
    targetSize.height *= displayScale;
    
    NSMutableDictionary<NSIndexPath *, AssetCollectionItemModel *> *prefetchingModelsByIndexPath = self.prefetchingModelsByIndexPath;
    
    for (NSIndexPath *indexPath in indexPaths) {
        assert(prefetchingModelsByIndexPath[indexPath] == nil);
        
        PHAssetCollection *collection = [self collectionAtIndexPath:indexPath];
        assert(collection != nil);
        AssetCollectionItemModel *model = [[AssetCollectionItemModel alloc] initWithCollection:collection];
        prefetchingModelsByIndexPath[indexPath] = model;
        [model requestImageWithTargetSize:targetSize];
        [model release];
    }
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableDictionary<NSIndexPath *, AssetCollectionItemModel *> *prefetchingModelsByIndexPath = self.prefetchingModelsByIndexPath;
    
    for (NSIndexPath *indexPath in indexPaths) {
        AssetCollectionItemModel *model = prefetchingModelsByIndexPath[indexPath];
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
        __block NSMutableDictionary<NSNumber *, PHFetchResult<PHAssetCollection *> *> *fetchResultsByCollectionType;
        dispatch_sync(dispatch_get_main_queue(), ^{
            fetchResultsByCollectionType = [self.mainQueue_fetchResultsByCollectionType mutableCopy];
        });
        
        NSMutableArray<NSIndexPath *> *removedIndexPaths = [NSMutableArray new];
        NSMutableArray<NSIndexPath *> *insertedIndexPaths = [NSMutableArray new];
        NSMutableArray<NSIndexPath *> *changedIndexPaths = [NSMutableArray new];
        
        for (NSNumber *collectionTypeNumber in fetchResultsByCollectionType.allKeys) {
            PHFetchResult<PHAssetCollection *> *fetchResult = fetchResultsByCollectionType[collectionTypeNumber];
            
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:fetchResult];
            if (!changeDetails.hasIncrementalChanges) continue;
            
            NSInteger sectionIndex = [self _sectionIndexOfCollectionType:static_cast<PHAssetCollectionType>(collectionTypeNumber.integerValue) fetchResultsByCollectionType:fetchResultsByCollectionType];
            assert(sectionIndex != NSNotFound);
            
            NSIndexSet *removedIndexes = changeDetails.removedIndexes;
            [removedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:sectionIndex];
                [removedIndexPaths addObject:indexPath];
            }];
            
            NSIndexSet *insertedIndexes = changeDetails.insertedIndexes;
            [insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:sectionIndex];
                [insertedIndexPaths addObject:indexPath];
            }];
            
            NSIndexSet *changedIndexes = changeDetails.changedIndexes;
            [changedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:sectionIndex];
                [changedIndexPaths addObject:indexPath];
            }];
            
            fetchResultsByCollectionType[collectionTypeNumber] = changeDetails.fetchResultAfterChanges;
        }
        
        if (removedIndexPaths.count == 0 && insertedIndexPaths.count == 0 && changedIndexPaths.count == 0) {
            [fetchResultsByCollectionType release];
            [removedIndexPaths release];
            [insertedIndexPaths release];
            [changedIndexPaths release];
            return;
        }
        
        // __block을 capture
        NSMutableDictionary<NSNumber *, PHFetchResult<PHAssetCollection *> *> *final_fetchResultsByCollectionType = [[fetchResultsByCollectionType retain] autorelease];
        [fetchResultsByCollectionType release];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UICollectionView *collectionView = self.collectionView;
            
            [collectionView performBatchUpdates:^{
                self.mainQueue_fetchResultsByCollectionType = final_fetchResultsByCollectionType;
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
