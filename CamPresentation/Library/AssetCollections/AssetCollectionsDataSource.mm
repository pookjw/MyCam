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

@interface AssetCollectionsDataSource () <UICollectionViewDataSource, PHPhotoLibraryAvailabilityObserver, PHPhotoLibraryChangeObserver>
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *cellRegistration;
@property (retain, nonatomic, readonly) UICollectionViewSupplementaryRegistration *supplementaryRegistration;
@property (retain, nonatomic, readonly) PHPhotoLibrary *photoLibrary;
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@property (retain, nonatomic, nullable) NSMutableDictionary<NSNumber *, PHFetchResult<PHAssetCollection *> *> *mainQueue_fetchResultsByCollectionType;
@property (nonatomic, readonly) std::vector<PHAssetCollectionType> allCollectionTypesSet;
@end

@implementation AssetCollectionsDataSource

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView cellRegistration:(UICollectionViewCellRegistration *)cellRegistration supplementaryRegistration:(UICollectionViewSupplementaryRegistration *)supplementaryRegistration {
    if (self = [super init]) {
        assert(collectionView.dataSource == nil);
        assert(collectionView.prefetchDataSource == nil);
        
        collectionView.dataSource = self;
        
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
                
                if (albumsFetchResult.count == 0) return;
                
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
    [_collectionView release];
    [_cellRegistration release];
    [_supplementaryRegistration release];
    [_photoLibrary unregisterChangeObserver:self];
    [_photoLibrary unregisterAvailabilityObserver:self];
    [_photoLibrary release];
    [_mainQueue_fetchResultsByCollectionType release];
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

- (NSInteger)sectionIndexOfCollectionType:(PHAssetCollectionType)collectionType {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    NSMutableDictionary<NSNumber *, PHFetchResult<PHAssetCollection *> *> *fetchResultsByCollectionType = self.mainQueue_fetchResultsByCollectionType;
    
    auto allCollectionTypesFilteredVector = self.allCollectionTypesSet
    | std::views::filter([fetchResultsByCollectionType](PHAssetCollectionType collectionType) -> BOOL {
        return [fetchResultsByCollectionType.allKeys containsObject:@(collectionType)];
    });
    
    auto iterator = std::find(allCollectionTypesFilteredVector.begin(), allCollectionTypesFilteredVector.end(), collectionType);
    
    if (iterator == allCollectionTypesFilteredVector.end()) {
        auto index = std::distance(allCollectionTypesFilteredVector.begin(), iterator);
        return index;
    } else {
        return NSNotFound;
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
    AssetCollectionItemModel *model = [[AssetCollectionItemModel alloc] initWithCollection:collection];
    
    __kindof UICollectionViewCell *cell = [collectionView dequeueConfiguredReusableCellWithRegistration:_cellRegistration forIndexPath:indexPath item:model];
    [model release];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueConfiguredReusableSupplementaryViewWithRegistration:_supplementaryRegistration forIndexPath:indexPath];
}

- (void)photoLibraryDidBecomeUnavailable:(PHPhotoLibrary *)photoLibrary {
    abort();
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // TODO
}

@end
