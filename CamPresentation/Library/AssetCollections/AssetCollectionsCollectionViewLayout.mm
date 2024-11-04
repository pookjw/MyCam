//
//  AssetCollectionsCollectionViewLayout.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/2/24.
//

#import <CamPresentation/AssetCollectionsCollectionViewLayout.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <algorithm>
#include <ranges>
#include <vector>
#include <string>

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */

@interface AssetCollectionsCollectionViewLayout ()
@property (retain, nonatomic, readonly) NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *itemAttributesByIndexPath;
@property (retain, nonatomic, readonly) NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *headerAttributesByIndexPath;
@property (retain, nonatomic, readonly) NSMutableDictionary<NSNumber *, id> *sectionDescriptorsBySectionIndex;
@end

@implementation AssetCollectionsCollectionViewLayout

- (instancetype)init {
    if (self = [super init]) {
        _itemAttributesByIndexPath = [NSMutableDictionary new];
        _headerAttributesByIndexPath = [NSMutableDictionary new];
        _sectionDescriptorsBySectionIndex = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)dealloc {
    [_itemAttributesByIndexPath release];
    [_headerAttributesByIndexPath release];
    [_sectionDescriptorsBySectionIndex release];
    [super dealloc];
}

- (CGSize)collectionViewContentSize {
    return self.collectionView.frame.size;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    [self reloadAttributesIfNeeded];
    [self reloadItemAttributes];
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<__kindof UICollectionViewLayoutAttributes *> *results = [NSMutableArray new];
    
    for (__kindof UICollectionViewLayoutAttributes *attributes in self.headerAttributesByIndexPath.allValues) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [results addObject:attributes];
        }
    }
    
    
#warning TODO
    unsigned int ivarsCount;
    Ivar *ivars = class_copyIvarList(objc_lookUpClass("_UICollectionLayoutSectionDescriptor"), &ivarsCount);
    
    auto _containerLayoutFrameIvar = std::ranges::find_if(ivars, ivars + ivarsCount, [](Ivar ivar) {
        auto name = ivar_getName(ivar);
        return !std::strcmp(name, "_containerLayoutFrame");
    });
    ptrdiff_t _containerLayoutFrameIffset = ivar_getOffset(*_containerLayoutFrameIvar);
    
    delete ivars;
    
    for (__kindof UICollectionViewLayoutAttributes *attributes in self.itemAttributesByIndexPath.allValues) {
        CGPoint orthogonalScrollingLayoutRect = reinterpret_cast<CGPoint (*)(id, SEL, NSInteger)>(objc_msgSend)(self, sel_registerName("_offsetForOrthogonalScrollingSection:"), attributes.indexPath.section);
        
        NSLog(@"%@", NSStringFromCGPoint(orthogonalScrollingLayoutRect));
    }
    
    [results addObjectsFromArray:self.itemAttributesByIndexPath.allValues];
    
    return [results autorelease];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return self.headerAttributesByIndexPath[indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.itemAttributesByIndexPath[indexPath];
}

- (BOOL)reloadAttributesIfNeeded {
    NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *headerAttributesByIndexPath = self.headerAttributesByIndexPath;
    NSMutableDictionary<NSNumber *, id> *sectionDescriptorsBySectionIndex = self.sectionDescriptorsBySectionIndex;
    
    UICollectionView * _Nullable collectionView = self.collectionView;
    if (collectionView == nil) {
        [headerAttributesByIndexPath removeAllObjects];
        [sectionDescriptorsBySectionIndex removeAllObjects];
        return NO;
    }
    
    NSInteger numberOfSections = collectionView.numberOfSections;
    
    if (numberOfSections == 0) {
        [headerAttributesByIndexPath removeAllObjects];
        [sectionDescriptorsBySectionIndex removeAllObjects];
        return NO;
    }
    
    assert(headerAttributesByIndexPath.count == sectionDescriptorsBySectionIndex.count);
    
    if (headerAttributesByIndexPath.count > 0) {
        return NO;
    }
    
    CGRect bounds = collectionView.bounds;
    CGFloat lastY = 0.;
    
    unsigned int ivarsCount;
    Ivar *ivars = class_copyIvarList(objc_lookUpClass("_UICollectionLayoutSectionDescriptor"), &ivarsCount);
    
    for (NSInteger sectionIndex : std::views::iota(0, numberOfSections)) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];
        NSInteger numberOfItems = [collectionView numberOfItemsInSection:sectionIndex];
        
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
        
        attributes.frame = CGRectMake(0., lastY, CGRectGetWidth(bounds), 40.);
        lastY += 40.;
        headerAttributesByIndexPath[indexPath] = attributes;
        
        id sectionDescriptor = [objc_lookUpClass("_UICollectionLayoutSectionDescriptor") new];
        
        std::for_each(ivars, ivars + ivarsCount, [sectionDescriptor, sectionIndex, bounds, lastY, numberOfItems](Ivar ivar) {
            const char *ivarName = ivar_getName(ivar);
            uintptr_t base = (uintptr_t)(sectionDescriptor);
            ptrdiff_t offset = ivar_getOffset(ivar);
            void *location = (void *)(base + offset);
            
            if (!std::strcmp(ivarName, "_axis")) {
                *reinterpret_cast<UIAxis *>(location) = UIAxisHorizontal;
            } else if (!std::strcmp(ivarName, "_orthogonalScrollingBehavior")) {
                *reinterpret_cast<UICollectionLayoutSectionOrthogonalScrollingBehavior *>(location) = UICollectionLayoutSectionOrthogonalScrollingBehaviorContinuousGroupLeadingBoundary;
            } else if (!std::strcmp(ivarName, "_groupDimension")) {
                *reinterpret_cast<CGFloat *>(location) = CGRectGetWidth(bounds);
            } else if (!std::strcmp(ivarName, "_layoutFrame") || !std::strcmp(ivarName, "_orthogonalScrollViewLayoutFrame") || !std::strcmp(ivarName, "_containerLayoutFrame")) {
                *reinterpret_cast<CGRect *>(location) = CGRectMake(0., lastY, CGRectGetWidth(bounds), 218.);
            } else if (!std::strcmp(ivarName, "_contentFrame")) {
                *reinterpret_cast<CGRect *>(location) = CGRectMake(0., 0., 200. * numberOfItems, 218.);
            } else if (!std::strcmp(ivarName, "_contentInsets")) {
                *reinterpret_cast<NSDirectionalEdgeInsets *>(location) = NSDirectionalEdgeInsetsZero;
            }
        });
        
        lastY += 218.;
        
        sectionDescriptorsBySectionIndex[@(sectionIndex)] = sectionDescriptor;
        [sectionDescriptor release];
    }
    
    delete ivars;
    
    assert(headerAttributesByIndexPath.count == sectionDescriptorsBySectionIndex.count);
    
    return YES;
}

- (void)reloadItemAttributes {
    NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *itemAttributesByIndexPath = self.itemAttributesByIndexPath;
    
    [itemAttributesByIndexPath removeAllObjects];
    
    UICollectionView * _Nullable collectionView = self.collectionView;
    if (collectionView == nil) {
        return;
    }
    
    NSInteger numberOfSections = collectionView.numberOfSections;
    if (numberOfSections == 0) {
        return;
    }
    
    NSMutableDictionary<NSNumber *, id> *sectionDescriptorsBySectionIndex = self.sectionDescriptorsBySectionIndex;
    
    unsigned int ivarsCount;
    Ivar *ivars = class_copyIvarList(objc_lookUpClass("_UICollectionLayoutSectionDescriptor"), &ivarsCount);
    
    auto _containerLayoutFrameIvar = std::ranges::find_if(ivars, ivars + ivarsCount, [](Ivar ivar) {
        auto name = ivar_getName(ivar);
        return !std::strcmp(name, "_containerLayoutFrame");
    });
    ptrdiff_t _containerLayoutFrameIffset = ivar_getOffset(*_containerLayoutFrameIvar);
    
    delete ivars;
    
    for (NSInteger sectionIndex : std::views::iota(0, numberOfSections)) {
        NSInteger numberOfItems = [collectionView numberOfItemsInSection:sectionIndex];
        
        if (numberOfItems == 0) continue;
        
        id sectionDescriptor = sectionDescriptorsBySectionIndex[@(sectionIndex)];
        CGRect _containerLayoutFrame = *reinterpret_cast<CGRect *>((uintptr_t)sectionDescriptor + _containerLayoutFrameIffset);
        
        for (NSInteger itemIndex : std::views::iota(0, numberOfItems)) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            
            attributes.frame = CGRectMake(CGRectGetMinX(_containerLayoutFrame) + 200. * itemIndex,
                                          CGRectGetMinY(_containerLayoutFrame),
                                          200.,
                                          218.);
            
            itemAttributesByIndexPath[indexPath] = attributes;
        }
    }
}

- (id)copySetionDescriptor:(id)oldDescriptor {
    if (oldDescriptor == nil) return nil;
    
    /*
     -[_UICollectionLayoutSectionDescriptor isEqualToSectionDescriptor:comparingContentOffset:]:
     0000000000385c50         sub        sp, sp, #0x30                               ; CODE XREF=-[_UICollectionViewOrthogonalScrollView configureForDescriptor:]+124
     0000000000385c54         stp        fp, lr, [sp, #0x20]
     0000000000385c58         add        fp, sp, #0x20
     0000000000385c5c         cbz        x0, loc_385d54
     
     0000000000385c60         cmp        x1, x0
     
     새로 생성하지 않으면 똑같다고 인지되어서 Orthogonal Layout이 업데이트 되지 않음. 따라서 반드시 Reload를 해야 한다.
     */
    
    id newDescriptor = [objc_lookUpClass("_UICollectionLayoutSectionDescriptor") new];
    
    // Ivar에 Swift (!BitwiseCopyable) / C++ Value가 없어야 함
    
    unsigned int ivarsCount;
    Ivar *ivars = class_copyIvarList(objc_lookUpClass("_UICollectionLayoutSectionDescriptor"), &ivarsCount);
    
    if (ivarsCount > 0) {
        ptrdiff_t minOffset = PTRDIFF_MAX;
        ptrdiff_t maxOffset = PTRDIFF_MIN;
        
        for (unsigned int idx = 0; idx < ivarsCount; idx++) {
            Ivar ivar = ivars[idx];
            ptrdiff_t offset = ivar_getOffset(ivar);
            minOffset = MIN(minOffset, offset);
            maxOffset = MAX(maxOffset, offset);
            
            if (strcmp(ivar_getTypeEncoding(ivar), @encode(id)) == 0) {
                id object = (id)((uintptr_t)self + offset) ;
                [object retain];
            }
        }
        
        assert(minOffset != PTRDIFF_MAX && maxOffset != PTRDIFF_MIN);
        
        // https://github.com/opensource-apple/objc4/blob/cd5e62a5597ea7a31dccef089317abb3a661c154/runtime/objc-runtime-new.h#L236
        uint32_t lastSize = *(uint32_t *)((uintptr_t)ivars[ivarsCount - 1] + sizeof(int32_t *) + sizeof(const char *) + sizeof(const char *) + sizeof(uint32_t));
        memcpy((void *)((uintptr_t)newDescriptor + minOffset), (const void *)((uintptr_t)oldDescriptor + minOffset), maxOffset - minOffset + lastSize);
    }
    
    delete ivars;
    
    return newDescriptor;
}

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    if ([preferredAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        return CGRectGetHeight(preferredAttributes.frame) != CGRectGetHeight(originalAttributes.frame);
    } else {
        return NO;
    }
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    UICollectionViewLayoutInvalidationContext *context = [UICollectionViewLayoutInvalidationContext new];
    
    NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *headerAttributesByIndexPath = self.headerAttributesByIndexPath;
    NSMutableDictionary<NSNumber *, id> *sectionDescriptorsBySectionIndex = self.sectionDescriptorsBySectionIndex;
    
    UICollectionViewLayoutAttributes *copiedAttributes = [headerAttributesByIndexPath[preferredAttributes.indexPath] copy];
    CGFloat diff = CGRectGetHeight(preferredAttributes.frame) - CGRectGetHeight(copiedAttributes.frame);
    
    copiedAttributes.frame = CGRectMake(CGRectGetMinX(copiedAttributes.frame),
                                        CGRectGetMinY(copiedAttributes.frame),
                                        CGRectGetWidth(copiedAttributes.frame),
                                        CGRectGetHeight(preferredAttributes.frame));
    
    self.headerAttributesByIndexPath[preferredAttributes.indexPath] = copiedAttributes;
    [copiedAttributes release];
    
    //
    
    {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:preferredAttributes.indexPath.item inSection:preferredAttributes.indexPath.section + 1];
        while (UICollectionViewLayoutAttributes *copiedAttributes = [headerAttributesByIndexPath[nextIndexPath] copy]) {
            id copiedSectionDescriptor = [self copySetionDescriptor:sectionDescriptorsBySectionIndex[@(nextIndexPath.section)]];
            assert(copiedSectionDescriptor != nil);
            
            copiedAttributes.frame = CGRectMake(CGRectGetMinX(copiedAttributes.frame),
                                                CGRectGetMinY(copiedAttributes.frame) + diff,
                                                CGRectGetWidth(copiedAttributes.frame),
                                                CGRectGetHeight(copiedAttributes.frame));
            
            headerAttributesByIndexPath[nextIndexPath] = copiedAttributes;
            [copiedAttributes release];
            
            //
            
            nextIndexPath = [NSIndexPath indexPathForItem:nextIndexPath.item inSection:nextIndexPath.section + 1];
        }
    }
    
    {
        unsigned int ivarsCount;
        Ivar *ivars = class_copyIvarList(objc_lookUpClass("_UICollectionLayoutSectionDescriptor"), &ivarsCount);
        
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:preferredAttributes.indexPath.item inSection:preferredAttributes.indexPath.section];
        while (id copiedSectionDescriptor = [self copySetionDescriptor:sectionDescriptorsBySectionIndex[@(nextIndexPath.section)]]) {
            std::for_each(ivars, ivars + ivarsCount, [copiedSectionDescriptor, diff](Ivar ivar) {
                const char *ivarName = ivar_getName(ivar);
                uintptr_t base = (uintptr_t)(copiedSectionDescriptor);
                ptrdiff_t offset = ivar_getOffset(ivar);
                void *location = (void *)(base + offset);
                
                if (!std::strcmp(ivarName, "_layoutFrame") || !std::strcmp(ivarName, "_orthogonalScrollViewLayoutFrame") || !std::strcmp(ivarName, "_containerLayoutFrame")) {
                    reinterpret_cast<CGRect *>(location)->origin.y += diff;
                }
            });
            
            sectionDescriptorsBySectionIndex[@(nextIndexPath.section)] = copiedSectionDescriptor;
            [copiedSectionDescriptor release];
            
            nextIndexPath = [NSIndexPath indexPathForItem:nextIndexPath.item inSection:nextIndexPath.section + 1];
        }
        
        delete ivars;
    }
    
    //
    
    return [context autorelease];
}

- (NSIndexSet *)_orthogonalScrollingSections {
    UICollectionView * _Nullable collectionView = self.collectionView;
    if (collectionView == nil) return nil;
    
    
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, collectionView.numberOfSections)];
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)_extendedAttributesQueryIncludingOrthogonalScrollingRegions:(struct CGRect)arg1 {
    objc_super superInfo = { self, [self class] };
    id result = reinterpret_cast<id (*)(objc_super *, SEL, CGRect)>(objc_msgSendSuper2)(&superInfo, _cmd, arg1);
    
//    NSLog(@"%@", result);
    
    return result;
}

- (BOOL)_hasOrthogonalScrollingSections {
    return YES;
}

- (id _Nonnull)_sectionDescriptorForSectionIndex:(NSInteger)sectionIndex {
    return self.sectionDescriptorsBySectionIndex[@(sectionIndex)];
}

- (BOOL)_shouldOrthogonalScrollingSectionSupplementaryScrollWithContentForIndexPath:(NSIndexPath *)indexPath elementKind:(NSString *)elementKind {
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        return NO;
    } else {
        objc_super superInfo = { self, [self class] };
        return reinterpret_cast<BOOL (*)(objc_super *, SEL, id, id)>(objc_msgSendSuper2)(&superInfo, _cmd, indexPath, elementKind);
    }
}

@end
