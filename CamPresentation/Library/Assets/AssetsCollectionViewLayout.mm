//
//  AssetsCollectionViewLayout.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetsCollectionViewLayout.h>
#include <cmath>
#include <vector>
#include <ranges>
#import <objc/message.h>
#import <objc/runtime.h>

OBJC_EXPORT id objc_msgSendSuper2(void);

@interface AssetsCollectionViewLayout ()
@property (retain, nonatomic, readonly) NSMutableDictionary<NSIndexPath *, NSValue *> *cachedFrameValuesByIndexPath;
@end

@implementation AssetsCollectionViewLayout

- (instancetype)init {
    if (self = [super init]) {
        _itemsPerRow = 4;
        _cachedFrameValuesByIndexPath = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)dealloc {
    [_cachedFrameValuesByIndexPath release];
    [super dealloc];
}

- (void)setItemsPerRow:(NSUInteger)itemsPerRow {
    assert(itemsPerRow > 0);
    
    if (_itemsPerRow != itemsPerRow) {
        _itemsPerRow = itemsPerRow;
        [self invalidateLayout]; // TOOD: Context
    }
}

- (void)prepareLayout {
    [super prepareLayout];
    
}

- (CGSize)collectionViewContentSize {
    UICollectionView * _Nullable collectionView = self.collectionView;
    if (collectionView == nil) return CGSizeZero;
    
    CGRect bounds = collectionView.bounds;
    if (CGRectIsNull(bounds)) return CGSizeZero;
    
    NSInteger numberOfItems = [collectionView numberOfItemsInSection:0];
    if (numberOfItems == 0) return CGSizeZero;
    
    NSInteger itemsPerRow = _itemsPerRow;
    assert(itemsPerRow > 0);
    
    // 0 이상
    NSInteger totalLastRow = numberOfItems / itemsPerRow;
    if (numberOfItems % itemsPerRow == 0) {
        totalLastRow -= 1;
    }
    
    CGFloat viewPortWidth = CGRectGetWidth(bounds);
    CGFloat itemSize = viewPortWidth / itemsPerRow;
    
    return CGSizeMake(viewPortWidth, (totalLastRow + 1) * itemSize);
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
    NSInteger itemsPerRow = _itemsPerRow;
    assert(itemsPerRow > 0);
    
    // 0 이상
    NSInteger totalLastRow = numberOfItems / itemsPerRow;
    if (numberOfItems % itemsPerRow == 0) {
        totalLastRow -= 1;
    }
    
    // rect는 bounds를 벗어날 수 있음 (회전시)
    CGFloat viewPortWidth = CGRectGetWidth(self.collectionView.bounds);
    CGFloat viewPortMinY = CGRectGetMinY(rect);
    CGFloat viewPortMaxY = CGRectGetMaxY(rect);
    
    CGFloat itemSize = viewPortWidth / itemsPerRow;
    // 0 이상
    auto viewPortFirstRow = static_cast<NSInteger>(std::floor(viewPortMinY / itemSize));
    auto viewPortLastRow = MIN(static_cast<NSInteger>(std::ceil(viewPortMaxY / itemSize)), totalLastRow);
    
    NSInteger firstIndex = viewPortFirstRow * itemsPerRow;
    NSInteger lastIndex;
    if (totalLastRow == viewPortLastRow) {
        lastIndex = viewPortLastRow * itemsPerRow + (numberOfItems % itemsPerRow) - 1;
    } else {
        lastIndex = (viewPortLastRow + 1) * itemsPerRow - 1;
    }
    
    firstIndex = MAX(firstIndex, 0);
    lastIndex = MAX(lastIndex, 0);
    
    NSMutableDictionary<NSIndexPath *, NSValue *> *cachedFrameValuesByIndexPath = self.cachedFrameValuesByIndexPath;
    
    auto vector = std::views::iota(firstIndex, lastIndex)
    | std::views::transform([itemsPerRow, itemSize, cachedFrameValuesByIndexPath](NSInteger index) -> UICollectionViewLayoutAttributes * {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        CGRect frame;
        if (NSValue *cahcedFrameValue = cachedFrameValuesByIndexPath[indexPath]) {
            frame = cahcedFrameValue.CGRectValue;
        } else {
            NSInteger column = index % itemsPerRow;
            CGFloat x = static_cast<CGFloat>(column) * itemSize;
            
            NSInteger row = index / itemsPerRow;
            CGFloat y = static_cast<CGFloat>(row) * itemSize;
            
            frame = CGRectMake(x, y, itemSize, itemSize);
            cachedFrameValuesByIndexPath[indexPath] = [NSValue valueWithCGRect:frame];
        }
        
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = frame;
        
        return attributes;
    })
    | std::ranges::to<std::vector<UICollectionViewLayoutAttributes *>>();
    
    NSArray<UICollectionViewLayoutAttributes *> *layoutAttributesArray = [[NSArray alloc] initWithObjects:vector.data() count:vector.size()];
    return [layoutAttributesArray autorelease];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionView * _Nullable collectionView = self.collectionView;
    if (collectionView == nil) return nil;
    
    NSMutableDictionary<NSIndexPath *, NSValue *> *cachedFrameValuesByIndexPath = self.cachedFrameValuesByIndexPath;
    
    CGRect frame;
    if (NSValue *cachedFrameValue = cachedFrameValuesByIndexPath[indexPath]) {
        frame = cachedFrameValue.CGRectValue;
    } else {
        CGRect bounds = collectionView.bounds;
        if (CGRectIsNull(bounds)) return nil;
        
        NSInteger itemsPerRow = _itemsPerRow;
        CGFloat itemSize = CGRectGetWidth(bounds) / itemsPerRow;
        
        NSInteger index = indexPath.item;
        
        NSInteger column = index % itemsPerRow;
        CGFloat x = static_cast<CGFloat>(column) * itemSize;
        
        NSInteger row = index / itemsPerRow;
        CGFloat y = static_cast<CGFloat>(row) * itemSize;
        
        frame = CGRectMake(x, y, itemSize, itemSize);
        
        cachedFrameValuesByIndexPath[indexPath] = [NSValue valueWithCGRect:frame];
    }
    
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.frame = frame;
    
    return attributes;
}

- (void)prepareForCollectionViewUpdates:(NSArray<UICollectionViewUpdateItem *> *)updateItems {
    NSInteger diffCount = 0;
    
    for (UICollectionViewUpdateItem *updateItem in updateItems) {
        switch (updateItem.updateAction) {
            case UICollectionUpdateActionInsert:
                diffCount += 1;
                break;
            case UICollectionUpdateActionDelete:
                diffCount -= 1;
                break;
            default:
                break;
        }
    }
    
    if (diffCount < 0) {
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
        NSMutableDictionary<NSIndexPath *, NSValue *> *cachedFrameValuesByIndexPath = self.cachedFrameValuesByIndexPath;
        
        for (NSInteger i = diffCount; i < 0; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:numberOfItems + i inSection:0];
            [cachedFrameValuesByIndexPath removeObjectForKey:indexPath];
        }
    }
    
    [super prepareForCollectionViewUpdates:updateItems];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return CGRectGetWidth(newBounds) != CGRectGetWidth(self.collectionView.bounds);
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    UICollectionViewLayoutInvalidationContext *context = [UICollectionViewLayoutInvalidationContext new];
    
    [context invalidateItemsAtIndexPaths:self.cachedFrameValuesByIndexPath.allKeys];
    [self.cachedFrameValuesByIndexPath removeAllObjects];
    
    return [context autorelease];
}

- (void)invalidateLayout {
    [super invalidateLayout];
}

- (BOOL)_estimatesSizes {
    return NO;
}

- (BOOL)_preparedForBoundsChanges {
    return YES;
}

@end
