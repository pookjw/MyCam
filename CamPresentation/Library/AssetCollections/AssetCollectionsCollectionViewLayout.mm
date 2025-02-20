//
//  AssetCollectionsCollectionViewLayout.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/2/24.
//

#import <CamPresentation/AssetCollectionsCollectionViewLayout.h>
#import <CamPresentation/AssetCollectionsCollectionViewLayoutInvalidationContext.h>
#import <CamPresentation/AssetCollectionsCollectionViewLayoutAttributes.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <algorithm>
#include <ranges>
#include <vector>
#include <string>

#define ESTIMATED_HEADER_HEIGHT 40.
#define ESTIMATED_ITEM_HEIGHT 100.

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */

@interface AssetCollectionsCollectionViewLayout ()
@property (retain, nonatomic, readonly) NSMutableDictionary<NSIndexPath *, AssetCollectionsCollectionViewLayoutAttributes *> *itemAttributesByIndexPath;
@property (retain, nonatomic, readonly) NSMutableDictionary<NSIndexPath *, AssetCollectionsCollectionViewLayoutAttributes *> *headerAttributesByIndexPath;
@property (retain, nonatomic, readonly) NSMutableDictionary<NSNumber *, id> *sectionDescriptorsBySectionIndex;
@end

@implementation AssetCollectionsCollectionViewLayout

+ (Class)invalidationContextClass {
    return AssetCollectionsCollectionViewLayoutInvalidationContext.class;
}

+ (Class)layoutAttributesClass {
    return AssetCollectionsCollectionViewLayoutAttributes.class;
}

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

- (void)_setCollectionView:(UICollectionView *)collectionView {
    objc_super superInfo = { self, [self class] };
    reinterpret_cast<void (*)(objc_super *, SEL, id)>(objc_msgSendSuper2)(&superInfo, _cmd, collectionView);
    
    reinterpret_cast<void (*)(id, SEL, BOOL, BOOL)>(objc_msgSend)(collectionView, sel_registerName("_setDefaultAlwaysBounceVertical:horizontal:"), YES, NO);
}

- (CGSize)collectionViewContentSize {
    NSInteger numberOfSections = self.collectionView.numberOfSections;
    if (numberOfSections == 0) return CGSizeZero;
    
    id sectionDescriptor = self.sectionDescriptorsBySectionIndex[@(numberOfSections - 1)];
    assert(sectionDescriptor != nil);
    
    Ivar ivar = object_getInstanceVariable(sectionDescriptor, "_containerLayoutFrame", NULL);
    assert(ivar != NULL);
    
    CGRect _containerLayoutFrame = *reinterpret_cast<CGRect *>((uintptr_t)sectionDescriptor + ivar_getOffset(ivar));
    
    CGSize contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds),
                                    CGRectGetMinY(_containerLayoutFrame) + CGRectGetHeight(_containerLayoutFrame));
    
    return contentSize;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    assert(self.sectionDescriptorsBySectionIndex.count == self.headerAttributesByIndexPath.count);
    
    if (self.sectionDescriptorsBySectionIndex.count == 0) {
        [self reloadSectionAndHeaderAttributes];
    }
    
    if (self.itemAttributesByIndexPath.count == 0) {
        [self reloadItemAttributes];
    }
}

- (void)prepareForCollectionViewUpdates:(NSArray<UICollectionViewUpdateItem *> *)updateItems {
    BOOL hasUpdate = NO;
    for (UICollectionViewUpdateItem *updateItem in updateItems) {
        switch (updateItem.updateAction) {
            case UICollectionUpdateActionInsert:
                hasUpdate = YES;
                break;
            case UICollectionUpdateActionDelete:
                hasUpdate = YES;
                break;
            default:
                break;
        }
        
        if (hasUpdate) {
            break;
        }
    }
    
    if (hasUpdate) {
        [self.sectionDescriptorsBySectionIndex removeAllObjects];
        [self.headerAttributesByIndexPath removeAllObjects];
        [self.itemAttributesByIndexPath removeAllObjects];
        [self reloadSectionAndHeaderAttributes];
        [self reloadItemAttributes];
    }
    
    [super prepareForCollectionViewUpdates:updateItems];
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<__kindof UICollectionViewLayoutAttributes *> *results = [NSMutableArray new];
    
    for (__kindof UICollectionViewLayoutAttributes *attributes in self.headerAttributesByIndexPath.allValues) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [results addObject:attributes];
        }
    }
    
    return [results autorelease];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return self.headerAttributesByIndexPath[indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.itemAttributesByIndexPath[indexPath];
}

- (void)reloadSectionAndHeaderAttributes {
    NSMutableDictionary<NSIndexPath *, AssetCollectionsCollectionViewLayoutAttributes *> *headerAttributesByIndexPath = self.headerAttributesByIndexPath;
    NSMutableDictionary<NSNumber *, id> *sectionDescriptorsBySectionIndex = self.sectionDescriptorsBySectionIndex;
    
    UICollectionView * _Nullable collectionView = self.collectionView;
    if (collectionView == nil) {
        [headerAttributesByIndexPath removeAllObjects];
        [sectionDescriptorsBySectionIndex removeAllObjects];
        return;
    }
    
    NSInteger numberOfSections = collectionView.numberOfSections;
    
    if (numberOfSections == 0) {
        [headerAttributesByIndexPath removeAllObjects];
        [sectionDescriptorsBySectionIndex removeAllObjects];
        return;
    }
    
    assert(headerAttributesByIndexPath.count == sectionDescriptorsBySectionIndex.count);
    
    [headerAttributesByIndexPath removeAllObjects];
    [sectionDescriptorsBySectionIndex removeAllObjects];
    
    CGRect bounds = collectionView.bounds;
    CGFloat lastY = 0.;
    
    unsigned int ivarsCount;
    Ivar *ivars = class_copyIvarList(objc_lookUpClass("_UICollectionLayoutSectionDescriptor"), &ivarsCount);
    
    for (NSInteger sectionIndex : std::views::iota(0, numberOfSections)) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];
        NSInteger numberOfItems = [collectionView numberOfItemsInSection:sectionIndex];
        
        AssetCollectionsCollectionViewLayoutAttributes *attributes = [AssetCollectionsCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
        
        attributes.frame = CGRectMake(0., lastY, CGRectGetWidth(bounds), ESTIMATED_HEADER_HEIGHT);
        attributes.originalY = lastY;
        
        lastY += ESTIMATED_HEADER_HEIGHT;
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
                *reinterpret_cast<CGFloat *>(location) = 208.;
            } else if (!std::strcmp(ivarName, "_layoutFrame") || !std::strcmp(ivarName, "_orthogonalScrollViewLayoutFrame") || !std::strcmp(ivarName, "_containerLayoutFrame")) {
                *reinterpret_cast<CGRect *>(location) = CGRectMake(0., lastY, CGRectGetWidth(bounds), ESTIMATED_ITEM_HEIGHT + 8. * 2.);
            } else if (!std::strcmp(ivarName, "_contentFrame")) {
                *reinterpret_cast<CGRect *>(location) = CGRectMake(8., 8., 200. * numberOfItems + 8. * (numberOfItems + 1), ESTIMATED_ITEM_HEIGHT);
            } else if (!std::strcmp(ivarName, "_contentInsets")) {
                *reinterpret_cast<NSDirectionalEdgeInsets *>(location) = NSDirectionalEdgeInsetsMake(8., 8., 8., 8.);
            } else if (!std::strcmp(ivarName, "_cornerRadius")) {
                *reinterpret_cast<CGFloat *>(location) = 20.;
            } else if (!std::strcmp(ivarName, "_clipsContentToBounds")) {
                *reinterpret_cast<BOOL *>(location) = YES;
            }
        });
        
        lastY += ESTIMATED_ITEM_HEIGHT + 8. * 2.;
        
        sectionDescriptorsBySectionIndex[@(sectionIndex)] = sectionDescriptor;
        [sectionDescriptor release];
    }
    
    delete ivars;
    
    assert(headerAttributesByIndexPath.count == sectionDescriptorsBySectionIndex.count);
}

- (void)reloadItemAttributes {
    NSMutableDictionary<NSIndexPath *, AssetCollectionsCollectionViewLayoutAttributes *> *itemAttributesByIndexPath = self.itemAttributesByIndexPath;
    
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
    
    auto _containerLayoutFrame_ivar = std::ranges::find_if(ivars, ivars + ivarsCount, [](Ivar ivar) {
        auto name = ivar_getName(ivar);
        return !std::strcmp(name, "_containerLayoutFrame");
    });
    ptrdiff_t _containerLayoutFrame_offset = ivar_getOffset(*_containerLayoutFrame_ivar);
    
    delete ivars;
    
    for (NSInteger sectionIndex : std::views::iota(0, numberOfSections)) {
        NSInteger numberOfItems = [collectionView numberOfItemsInSection:sectionIndex];
        
        if (numberOfItems == 0) continue;
        
        id sectionDescriptor = sectionDescriptorsBySectionIndex[@(sectionIndex)];
        assert(sectionDescriptor != nil);
        CGRect _containerLayoutFrame = *reinterpret_cast<CGRect *>((uintptr_t)sectionDescriptor + _containerLayoutFrame_offset);
        
        for (NSInteger itemIndex : std::views::iota(0, numberOfItems)) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
            
            AssetCollectionsCollectionViewLayoutAttributes *attributes = [AssetCollectionsCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            
            attributes.frame = CGRectMake(CGRectGetMinX(_containerLayoutFrame) + (200. * itemIndex) + (8. * (itemIndex + 1)),
                                          CGRectGetMinY(_containerLayoutFrame) + 8.,
                                          200.,
                                          ESTIMATED_ITEM_HEIGHT);
            
            itemAttributesByIndexPath[indexPath] = attributes;
        }
    }
}

- (id)copySectionDescriptor:(id)oldDescriptor {
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
//    if ([preferredAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
//        return CGRectGetHeight(preferredAttributes.frame) != CGRectGetHeight(originalAttributes.frame);
//    } else {
//        return NO;
//    }
    return CGRectGetHeight(preferredAttributes.frame) != CGRectGetHeight(originalAttributes.frame);
//    return NO;
}

- (AssetCollectionsCollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    auto context = static_cast<AssetCollectionsCollectionViewLayoutInvalidationContext *>([super invalidationContextForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes]);
    
    assert(context.preferredAttributes == nil);
    context.preferredAttributes = preferredAttributes;
    assert(context.originalAttributes == nil);
    context.originalAttributes = originalAttributes;
    
    if (NSString *representedElementKind = preferredAttributes.representedElementKind) {
        [context invalidateSupplementaryElementsOfKind:representedElementKind atIndexPaths:@[preferredAttributes.indexPath]];
    } else {
        [context invalidateItemsAtIndexPaths:@[preferredAttributes.indexPath]];
    }
    
    return context;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return (CGRectGetWidth(newBounds) != CGRectGetWidth(self.collectionView.bounds)) || (CGRectGetMinY(newBounds) != CGRectGetMinY(self.collectionView.bounds));
}

- (AssetCollectionsCollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    auto context = static_cast<AssetCollectionsCollectionViewLayoutInvalidationContext *>([super invalidationContextForBoundsChange:newBounds]);
    
    CGRect oldBounds = self.collectionView.bounds;
    
    context.oldBounds = oldBounds;
    context.newBounds = newBounds;
    
    if (CGRectGetWidth(oldBounds) != CGRectGetWidth(newBounds)) {
        // Width가 바뀌었을 때
        [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:self.headerAttributesByIndexPath.allKeys];
        
        NSMutableIndexSet *_orthogonalSectionsWithContentSizeChanges = [NSMutableIndexSet new];
        for (NSNumber *sectionIndexNumber in self.sectionDescriptorsBySectionIndex.allKeys) {
            [_orthogonalSectionsWithContentSizeChanges addIndex:sectionIndexNumber.unsignedIntegerValue];
        }
        
        NSMutableIndexSet *_old_orthogonalSectionsWithContentSizeChanges;
        assert(object_getInstanceVariable(context, "_orthogonalSectionsWithContentSizeChanges", reinterpret_cast<void **>(&_old_orthogonalSectionsWithContentSizeChanges)));
        [_old_orthogonalSectionsWithContentSizeChanges release];
        
        assert(object_setInstanceVariable(context, "_orthogonalSectionsWithContentSizeChanges", reinterpret_cast<void *>(_orthogonalSectionsWithContentSizeChanges)) != NULL);
        [_orthogonalSectionsWithContentSizeChanges release];
    } else if (CGRectGetMinY(oldBounds) != CGRectGetMinY(newBounds)) {
        // 상하로 스크롤 했을 때 Header만 갱신
        [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:self.headerAttributesByIndexPath.allKeys];
    }
    
    return context;
}

- (void)invalidateLayoutWithContext:(AssetCollectionsCollectionViewLayoutInvalidationContext *)context {
    if (context.invalidateEverything) {
        [self.sectionDescriptorsBySectionIndex removeAllObjects];
        [self.headerAttributesByIndexPath removeAllObjects];
        [self.itemAttributesByIndexPath removeAllObjects];
    } else if (!CGRectIsNull(context.newBounds)) {
        CGRect oldBounds = context.oldBounds;
        CGRect newBounds = context.newBounds;
        
        if (CGRectGetWidth(oldBounds) != CGRectGetWidth(newBounds)) {
            // width가 바뀌었다면 Header, Section Frame 업데이트
            CGFloat width = CGRectGetWidth(context.newBounds);
            
            NSMutableDictionary<NSIndexPath *, AssetCollectionsCollectionViewLayoutAttributes *> *headerAttributesByIndexPath = self.headerAttributesByIndexPath;
            
            for (NSIndexPath *indexPath in headerAttributesByIndexPath.allKeys) {
                AssetCollectionsCollectionViewLayoutAttributes *copy = [headerAttributesByIndexPath[indexPath] copy];
                
                copy.frame = CGRectMake(CGRectGetMinX(copy.frame),
                                        CGRectGetMinY(copy.frame),
                                        width,
                                        CGRectGetHeight(copy.frame));
                
                headerAttributesByIndexPath[indexPath] = copy;
                [copy release];
            }
            
            unsigned int ivarsCount;
            Ivar *ivars = class_copyIvarList(objc_lookUpClass("_UICollectionLayoutSectionDescriptor"), &ivarsCount);
            
            NSMutableDictionary<NSNumber *, id> *sectionDescriptorsBySectionIndex = self.sectionDescriptorsBySectionIndex;
            
            for (NSNumber *sectionIndex in sectionDescriptorsBySectionIndex.allKeys) {
                id copy = [self copySectionDescriptor:sectionDescriptorsBySectionIndex[sectionIndex]];
                
                std::for_each(ivars, ivars + ivarsCount, [copy, width](Ivar ivar) {
                    const char *ivarName = ivar_getName(ivar);
                    uintptr_t base = (uintptr_t)(copy);
                    ptrdiff_t offset = ivar_getOffset(ivar);
                    void *location = (void *)(base + offset);
                    
                    if (!std::strcmp(ivarName, "_layoutFrame") || !std::strcmp(ivarName, "_orthogonalScrollViewLayoutFrame") || !std::strcmp(ivarName, "_containerLayoutFrame")) {
                        reinterpret_cast<CGRect *>(location)->size.width = width;
                    }
                });
                
                sectionDescriptorsBySectionIndex[sectionIndex] = copy;
                [copy release];
            }
            
            delete ivars;
        } else if (CGRectGetMinY(oldBounds) != CGRectGetMinY(newBounds)) {
            // 상하로 스크롤하면 Header 업데이트
            UIEdgeInsets _effectiveContentInset = reinterpret_cast<UIEdgeInsets (*)(id, SEL)>(objc_msgSend)(self.collectionView, sel_registerName("_effectiveContentInset"));
            
            NSMutableDictionary<NSIndexPath *, AssetCollectionsCollectionViewLayoutAttributes *> *headerAttributesByIndexPath = self.headerAttributesByIndexPath;
            
            for (NSIndexPath *indexPath in headerAttributesByIndexPath.allKeys) {
                AssetCollectionsCollectionViewLayoutAttributes *copy = [headerAttributesByIndexPath[indexPath] copy];
                
                //
                
                id sectionDescriptor = self.sectionDescriptorsBySectionIndex[@(indexPath.section)];
                
                Ivar ivar = object_getInstanceVariable(sectionDescriptor, "_containerLayoutFrame", NULL);
                assert(ivar != NULL);
                
                CGRect _containerLayoutFrame = *reinterpret_cast<CGRect *>((uintptr_t)sectionDescriptor + ivar_getOffset(ivar));
                
                //
                
                CGFloat adjustedContentOffsetY = CGRectGetMinY(newBounds) + _effectiveContentInset.top;
                
                CGFloat y;
                if (CGRectGetMaxY(_containerLayoutFrame) - CGRectGetHeight(copy.frame) <= adjustedContentOffsetY) {
                    // 맨 위로 이동할 떄
                    y = CGRectGetMaxY(_containerLayoutFrame) - CGRectGetHeight(copy.frame);
                } else if ((CGRectGetMinY(_containerLayoutFrame) - CGRectGetHeight(copy.frame)) <= adjustedContentOffsetY) {
                    // Section을 스크롤 중일 때
                    y = CGRectGetMinY(newBounds) + _effectiveContentInset.top;
                } else {
                    // 아래에 있을 때
                    y = copy.originalY;
                }
                
                copy.frame = CGRectMake(CGRectGetMinX(copy.frame),
                                        y,
                                        CGRectGetWidth(copy.frame),
                                        CGRectGetHeight(copy.frame));
                
                headerAttributesByIndexPath[indexPath] = copy;
                [copy release];
            }
        }
    } else if (UICollectionViewLayoutAttributes *preferredAttributes = context.preferredAttributes) {
        UICollectionViewLayoutAttributes *originalAttributes = context.originalAttributes;
        assert(originalAttributes != nil);
        
        // Estimated 업데이트
        
        NSMutableDictionary<NSIndexPath *, AssetCollectionsCollectionViewLayoutAttributes *> *headerAttributesByIndexPath = self.headerAttributesByIndexPath;
        NSMutableDictionary<NSNumber *, id> *sectionDescriptorsBySectionIndex = self.sectionDescriptorsBySectionIndex;
        NSMutableDictionary<NSIndexPath *, AssetCollectionsCollectionViewLayoutAttributes *> *itemAttributesByIndexPath = self.itemAttributesByIndexPath;
        
        CGFloat diff;
        NSInteger headerAdjustmentIndex;
        NSInteger sectionAdjustmentIndex;
        NSInteger itemAdjustmentIndex;
        
        if ([preferredAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            // Header 크기가 바뀌었다면
            AssetCollectionsCollectionViewLayoutAttributes *copiedAttributes = [headerAttributesByIndexPath[preferredAttributes.indexPath] copy];
            
            copiedAttributes.frame = CGRectMake(CGRectGetMinX(copiedAttributes.frame),
                                                CGRectGetMinY(copiedAttributes.frame),
                                                CGRectGetWidth(copiedAttributes.frame),
                                                CGRectGetHeight(preferredAttributes.frame));
            
            diff = CGRectGetHeight(preferredAttributes.frame) - CGRectGetHeight(originalAttributes.frame);
            assert(diff != 0.);
            
            headerAttributesByIndexPath[preferredAttributes.indexPath] = copiedAttributes;
            [copiedAttributes release];
            
            [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:@[preferredAttributes.indexPath]];
            
            headerAdjustmentIndex = preferredAttributes.indexPath.section + 1;
            sectionAdjustmentIndex = preferredAttributes.indexPath.section;
            itemAdjustmentIndex = preferredAttributes.indexPath.section;
        } else if (preferredAttributes.representedElementKind == nil) {
            // Item 크기가 바뀌었다면
            AssetCollectionsCollectionViewLayoutAttributes *copiedAttributes = [itemAttributesByIndexPath[preferredAttributes.indexPath] copy];
            
            copiedAttributes.frame = CGRectMake(CGRectGetMinX(copiedAttributes.frame),
                                                CGRectGetMinY(copiedAttributes.frame),
                                                CGRectGetWidth(copiedAttributes.frame),
                                                CGRectGetHeight(preferredAttributes.frame));
            
            itemAttributesByIndexPath[preferredAttributes.indexPath] = copiedAttributes;
            [copiedAttributes release];
            
            [context invalidateItemsAtIndexPaths:@[preferredAttributes.indexPath]];
            
            CGFloat maxHeight = 0.;
            for (UICollectionViewLayoutAttributes *attributes in itemAttributesByIndexPath.allValues) {
                if (attributes.indexPath.section == preferredAttributes.indexPath.section) {
                    maxHeight = MAX(maxHeight, CGRectGetHeight(attributes.frame));
                }
            }
            
            //
            
            /*
             필요할 때만 (값이 다를 떄만 복사해야함)
             -[_UICollectionViewOrthogonalScrollView configureForDescriptor:]
             안 그러면 -[UIScrollView setContentOffset:]이 계속 불려서 Scroll이 안 됨
             */
            id sectionDescriptor = sectionDescriptorsBySectionIndex[@(preferredAttributes.indexPath.section)];
            assert(sectionDescriptor != nil);
            
            unsigned int ivarsCount;
            Ivar *ivars = class_copyIvarList(objc_lookUpClass("_UICollectionLayoutSectionDescriptor"), &ivarsCount);
            
            CGFloat originalHeight;
            
            std::for_each(ivars, ivars + ivarsCount, [sectionDescriptor, maxHeight, &originalHeight](Ivar ivar) {
                const char *ivarName = ivar_getName(ivar);
                uintptr_t base = (uintptr_t)(sectionDescriptor);
                ptrdiff_t offset = ivar_getOffset(ivar);
                void *location = (void *)(base + offset);
                
                if (!std::strcmp(ivarName, "_layoutFrame") || !std::strcmp(ivarName, "_orthogonalScrollViewLayoutFrame") || !std::strcmp(ivarName, "_containerLayoutFrame")) {
                    reinterpret_cast<CGRect *>(location)->size.height = maxHeight + 8. * 2.;
                } else if (!std::strcmp(ivarName, "_contentFrame")) {
                    originalHeight = CGRectGetHeight(*reinterpret_cast<CGRect *>(location));
                    reinterpret_cast<CGRect *>(location)->size.height = maxHeight;
                }
            });
            
            delete ivars;
            
            diff = maxHeight - originalHeight;
            
            headerAdjustmentIndex = preferredAttributes.indexPath.section + 1;
            sectionAdjustmentIndex = preferredAttributes.indexPath.section + 1;
            itemAdjustmentIndex = preferredAttributes.indexPath.section + 1;
        } else {
            abort();
        }
        
        //
        
        if (diff != 0.) {
            // Header 위치 업데이트
            {
                for (NSInteger sectionIndex : std::views::iota(headerAdjustmentIndex, self.collectionView.numberOfSections)) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];
                    AssetCollectionsCollectionViewLayoutAttributes *copiedAttributes = [headerAttributesByIndexPath[indexPath] copy];
                    assert(copiedAttributes != nil);
                    
                    copiedAttributes.frame = CGRectMake(CGRectGetMinX(copiedAttributes.frame),
                                                        CGRectGetMinY(copiedAttributes.frame) + diff,
                                                        CGRectGetWidth(copiedAttributes.frame),
                                                        CGRectGetHeight(copiedAttributes.frame));
                    copiedAttributes.originalY = CGRectGetMinY(copiedAttributes.frame);
                    
                    headerAttributesByIndexPath[indexPath] = copiedAttributes;
                    [copiedAttributes release];
                    
                    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:@[indexPath]];
                    
                    //
                    
                }
            }
            
            // Section Scroll View 업데이트
            {
                unsigned int ivarsCount;
                Ivar *ivars = class_copyIvarList(objc_lookUpClass("_UICollectionLayoutSectionDescriptor"), &ivarsCount);
                
                for (NSInteger sectionIndex : std::views::iota(sectionAdjustmentIndex, self.collectionView.numberOfSections)) {
                    id copiedSectionDescriptor = [self copySectionDescriptor:sectionDescriptorsBySectionIndex[@(sectionIndex)]];
                    assert(copiedSectionDescriptor != nil);
                    
                    std::for_each(ivars, ivars + ivarsCount, [copiedSectionDescriptor, diff](Ivar ivar) {
                        const char *ivarName = ivar_getName(ivar);
                        
                        if (!std::strcmp(ivarName, "_layoutFrame") || !std::strcmp(ivarName, "_orthogonalScrollViewLayoutFrame") || !std::strcmp(ivarName, "_containerLayoutFrame")) {
                            uintptr_t base = (uintptr_t)(copiedSectionDescriptor);
                            ptrdiff_t offset = ivar_getOffset(ivar);
                            void *location = (void *)(base + offset);
                            
                            reinterpret_cast<CGRect *>(location)->origin.y += diff;
                        }
                    });
                    
                    sectionDescriptorsBySectionIndex[@(sectionIndex)] = copiedSectionDescriptor;
                    [copiedSectionDescriptor release];
                }
                
                delete ivars;
            }
            
            // Item 위치 업데이트
            {
                NSInteger numberOfSection = self.collectionView.numberOfSections;
                for (NSInteger sectionIndex : std::views::iota(itemAdjustmentIndex, numberOfSection)) {
                    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:sectionIndex];
                    
                    for (NSInteger itemIndex : std::views::iota(0, numberOfItems)) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
                        
                        /*
                         필요할 때만 (값이 다를 떄만 복사해야함)
                         -[_UICollectionViewOrthogonalScrollView configureForDescriptor:]
                         안 그러면 -[UIScrollView setContentOffset:]이 계속 불려서 Scroll이 안 됨
                         `diff != 0.`이 방지해줄 것
                         */
                        
                        AssetCollectionsCollectionViewLayoutAttributes *copiedAttributes = [itemAttributesByIndexPath[indexPath] copy];
                        CGRect frame = copiedAttributes.frame;
                        frame.origin.y += diff;
                        copiedAttributes.frame = frame;
                        
                        itemAttributesByIndexPath[indexPath] = copiedAttributes;
                        [copiedAttributes release];
                        
                        [context invalidateItemsAtIndexPaths:@[indexPath]];
                    }
                }
            }
        }
    }
    
    [super invalidateLayoutWithContext:context];
}

- (NSIndexSet *)_orthogonalScrollingSections {
    UICollectionView * _Nullable collectionView = self.collectionView;
    if (collectionView == nil) return nil;
    
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, collectionView.numberOfSections)];
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)_extendedAttributesQueryIncludingOrthogonalScrollingRegions:(struct CGRect)arg1 {
    objc_super superInfo = { self, [self class] };
    NSMutableArray<__kindof UICollectionViewLayoutAttributes *> *results = [reinterpret_cast<id (*)(objc_super *, SEL, CGRect)>(objc_msgSendSuper2)(&superInfo, _cmd, arg1) mutableCopy];
    
    //
    
    unsigned int ivarsCount;
    Ivar *ivars = class_copyIvarList(objc_lookUpClass("_UICollectionLayoutSectionDescriptor"), &ivarsCount);
    
    auto _contentOffset_ivar = std::ranges::find_if(ivars, ivars + ivarsCount, [](Ivar ivar) {
        auto name = ivar_getName(ivar);
        return !std::strcmp(name, "_contentOffset");
    });
    ptrdiff_t _contentOffset_offset = ivar_getOffset(*_contentOffset_ivar);
    
    auto _containerLayoutFrame_ivar = std::ranges::find_if(ivars, ivars + ivarsCount, [](Ivar ivar) {
        auto name = ivar_getName(ivar);
        return !std::strcmp(name, "_containerLayoutFrame");
    });
    ptrdiff_t _containerLayoutFrame_offset = ivar_getOffset(*_containerLayoutFrame_ivar);
    
    delete ivars;
    
    NSMutableDictionary<NSNumber *, id> *sectionDescriptorsBySectionIndex = self.sectionDescriptorsBySectionIndex;
    
    for (__kindof UICollectionViewLayoutAttributes *attributes in self.itemAttributesByIndexPath.allValues) {
        id sectionDescriptor = sectionDescriptorsBySectionIndex[@(attributes.indexPath.section)];
        
        CGPoint _contentOffset = *reinterpret_cast<CGPoint *>((uintptr_t)sectionDescriptor + _contentOffset_offset);
        CGRect _containerLayoutFrame = *reinterpret_cast<CGRect *>((uintptr_t)sectionDescriptor + _containerLayoutFrame_offset);
        
        CGRect bounds = CGRectOffset(_containerLayoutFrame, _contentOffset.x, _contentOffset.y);
        
        if (CGRectIntersectsRect(bounds, attributes.frame)) {
            [results addObject:attributes];
        }
    }
    
    return [results autorelease];
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


//- (BOOL)_estimatesSupplementaryItems {
//    return YES;
//}

- (BOOL)_estimatesSizes {
    return YES;
}

- (BOOL)_supportsPrefetchingWithEstimatedSizes {
    return YES;
}

- (void)_prepareForPreferredAttributesQueryForView:(__kindof UICollectionReusableView *)view withLayoutAttributes:(__kindof UICollectionViewLayoutAttributes *)layoutAttributes {
    objc_super superInfo = { self, [self class] };
    reinterpret_cast<void (*)(objc_super *, SEL, id, id)>(objc_msgSendSuper2)(&superInfo, _cmd, view, layoutAttributes);
    
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(view, sel_registerName("_setShouldConstrainWidth:"), YES);
}

- (BOOL)_preparedForBoundsChanges {
    return YES;
}

@end
