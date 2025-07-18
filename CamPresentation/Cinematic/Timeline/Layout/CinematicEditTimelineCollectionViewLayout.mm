//
//  CinematicEditTimelineCollectionViewLayout.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicEditTimelineCollectionViewLayout.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <CamPresentation/CinematicEditTimelineCollectionViewLayoutAttributes.h>
#include <ranges>
#import <CamPresentation/CinematicEditTimelineSectionModel.h>
#import <CamPresentation/CinematicEditTimelineItemModel.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <CamPresentation/CinematicEditTimelinePlayheadView.h>
#import <CamPresentation/CinematicEditTimelineCollectionViewLayoutInvalidationContext.h>
#import <CamPresentation/CinematicEditTimelineVideoThumbnailView.h>
#import <CamPresentation/CinematicEditTimelineDetectionsThumbnailView.h>
#import <CamPresentation/CinematicEditTimelineDisparityThumbnailView.h>

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */

NSString * const CinematicEditTimelineCollectionViewLayoutVideoThumbnailSupplementaryElementKind = NSStringFromClass([CinematicEditTimelineVideoThumbnailView class]);
NSString * const CinematicEditTimelineCollectionViewLayoutDisparityThumbnailSupplementaryElementKind = NSStringFromClass([CinematicEditTimelineDisparityThumbnailView class]);
NSString * const CinematicEditTimelineCollectionViewLayoutDetectionThumbnailSupplementaryElementKind = NSStringFromClass([CinematicEditTimelineDetectionsThumbnailView class]);

@interface CinematicEditTimelineCollectionViewLayout ()
@property (assign, nonatomic, setter=_setCollectionViewContentSize:) CGSize collectionViewContentSize;
@property (copy, nonatomic, direct, nullable, getter=_cachedLayoutAttributesByIndexPath, setter=_setCachedLayoutAttributesByIndexPath:) NSDictionary<NSIndexPath *, CinematicEditTimelineCollectionViewLayoutAttributes *> *cachedLayoutAttributesByIndexPath;
@property (copy, nonatomic, direct, nullable, getter=_cachedVideoThumbnailLayoutAttibutesByIndexPath, setter=_setCachedVideoThumbnailLayoutAttibutesByIndexPath:) NSDictionary<NSIndexPath *, CinematicEditTimelineCollectionViewLayoutAttributes *> *cachedVideoThumbnailLayoutAttibutesByIndexPath;
@property (copy, nonatomic, direct, nullable, getter=_cachedDisparityThumbnailLayoutAttibutesByIndexPath, setter=_setCachedDisparityThumbnailLayoutAttibutesByIndexPath:) NSDictionary<NSIndexPath *, CinematicEditTimelineCollectionViewLayoutAttributes *> *cachedDisparityThumbnailLayoutAttibutesByIndexPath;
@property (copy, nonatomic, direct, nullable, getter=_cachedDetectionThumbnailLayoutAttibutesByIndexPath, setter=_setCachedDetectionThumbnailLayoutAttibutesByIndexPath:) NSDictionary<NSIndexPath *, CinematicEditTimelineCollectionViewLayoutAttributes *> *cachedDetectionThumbnailLayoutAttibutesByIndexPath;
@property (copy, nonatomic, direct, nullable, getter=_playheadLayoutAttributes, setter=_setPlayheadLayoutAttributes:) CinematicEditTimelineCollectionViewLayoutAttributes *playheadLayoutAttributes;
@end

@implementation CinematicEditTimelineCollectionViewLayout

+ (Class)layoutAttributesClass {
    return [CinematicEditTimelineCollectionViewLayoutAttributes class];
}

+ (Class)invalidationContextClass {
    return [CinematicEditTimelineCollectionViewLayoutInvalidationContext class];
}

- (instancetype)init {
    if (self = [super init]) {
        _pixelsForSecond = 30.;
        [self registerClass:[CinematicEditTimelinePlayheadView class] forDecorationViewOfKind:NSStringFromClass([CinematicEditTimelinePlayheadView class])];
    }
    
    return self;
}

- (void)dealloc {
    [_cachedLayoutAttributesByIndexPath release];
    [_cachedVideoThumbnailLayoutAttibutesByIndexPath release];
    [_cachedDisparityThumbnailLayoutAttibutesByIndexPath release];
    [_cachedDetectionThumbnailLayoutAttibutesByIndexPath release];
    [_playheadLayoutAttributes release];
    [super dealloc];
}

- (void)setPixelsForSecond:(CGFloat)pixelsForSecond {
    _pixelsForSecond = pixelsForSecond;
    [self invalidateLayout];
}

- (CMTime)timeFromContentOffset:(CGPoint)contentOffset {
    UICollectionView *collectionView = self.collectionView;
    if (collectionView == nil) return kCMTimeInvalid;
    
    return CMTimeMake(contentOffset.x, self.pixelsForSecond);
}

- (CGPoint)contentOffsetFromTime:(CMTime)time {
    CGFloat xOffset = CMTimeConvertScale(time, self.pixelsForSecond, kCMTimeRoundingMethod_Default).value;
    return CGPointMake(xOffset, 0.);
}

- (void)prepareLayout {
    [super prepareLayout];
    
    UICollectionView *collectionView = self.collectionView;
    if (collectionView == nil) {
        self.cachedLayoutAttributesByIndexPath = nil;
        self.cachedVideoThumbnailLayoutAttibutesByIndexPath = nil;
        self.cachedDetectionThumbnailLayoutAttibutesByIndexPath = nil;
        return;
    }
    
    auto dataSource = static_cast<UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel *, CinematicEditTimelineItemModel *> *>(collectionView.dataSource);
    assert([dataSource isKindOfClass:[UICollectionViewDiffableDataSource class]]);
    
    NSMutableDictionary<NSIndexPath *, CinematicEditTimelineCollectionViewLayoutAttributes *> *cachedLayoutAttributesByIndexPath = [NSMutableDictionary new];
    NSMutableDictionary<NSIndexPath *, CinematicEditTimelineCollectionViewLayoutAttributes *> *cachedVideoThumbnailLayoutAttibutesByIndexPath = [NSMutableDictionary new];
    NSMutableDictionary<NSIndexPath *, CinematicEditTimelineCollectionViewLayoutAttributes *> *cachedDisparityThumbnailLayoutAttibutesByIndexPath = [NSMutableDictionary new];
    NSMutableDictionary<NSIndexPath *, CinematicEditTimelineCollectionViewLayoutAttributes *> *cachedDetectionThumbnailLayoutAttibutesByIndexPath = [NSMutableDictionary new];
    
    CGFloat halfBoundsWidth = CGRectGetWidth(collectionView.bounds) * 0.5;
    CGFloat maxXOffset = 0.;
    CGFloat yOffset = 0.;
    CGFloat pixelsForSecond = self.pixelsForSecond;
    
    for (NSInteger sectionIndex : std::views::iota(0, collectionView.numberOfSections)) {
        CinematicEditTimelineSectionModel *sectionModel = [dataSource sectionIdentifierForIndex:sectionIndex];
        assert(sectionModel != nil);
        NSInteger numberOfItems = [collectionView numberOfItemsInSection:sectionIndex];
        
        CGFloat minXForThumbnails = CGFLOAT_MAX;
        CGFloat maxXForThumbnails = CGFLOAT_MIN;
        
        for (NSInteger itemIndex : std::views::iota(0, numberOfItems)) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
            CinematicEditTimelineItemModel *itemModel = [dataSource itemIdentifierForIndexPath:indexPath];
            assert(itemModel != nil);
            
            CinematicEditTimelineCollectionViewLayoutAttributes *layoutAttributes = [CinematicEditTimelineCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            
            switch (itemModel.type) {
                case CinematicEditTimelineItemModelTypeVideoTrack: {
                    CMTimeRange timeRange = sectionModel.timeRange;
                    assert(CMTIMERANGE_IS_VALID(timeRange));
                    
                    CGFloat xOffset = halfBoundsWidth + CMTimeConvertScale(timeRange.start, pixelsForSecond, kCMTimeRoundingMethod_Default).value;
                    CGFloat width = CMTimeConvertScale(timeRange.duration, pixelsForSecond, kCMTimeRoundingMethod_Default).value;
                    
                    layoutAttributes.frame = CGRectMake(xOffset,
                                                        yOffset,
                                                        width,
                                                        50.);
                    maxXOffset = MAX(xOffset + width, maxXOffset);
                    
                    minXForThumbnails = MIN(minXForThumbnails, CGRectGetMinX(layoutAttributes.frame));
                    maxXForThumbnails = MAX(maxXForThumbnails, CGRectGetMaxX(layoutAttributes.frame));
                    
                    layoutAttributes.zIndex = 0;
                    break;
                }
                case CinematicEditTimelineItemModelTypeDisparityTrack: {
                    CMTimeRange timeRange = sectionModel.timeRange;
                    assert(CMTIMERANGE_IS_VALID(timeRange));
                    
                    CGFloat xOffset = halfBoundsWidth + CMTimeConvertScale(timeRange.start, pixelsForSecond, kCMTimeRoundingMethod_Default).value;
                    CGFloat width = CMTimeConvertScale(timeRange.duration, pixelsForSecond, kCMTimeRoundingMethod_Default).value;
                    
                    layoutAttributes.frame = CGRectMake(xOffset,
                                                        yOffset,
                                                        width,
                                                        50.);
                    maxXOffset = MAX(xOffset + width, maxXOffset);
                    
                    minXForThumbnails = MIN(minXForThumbnails, CGRectGetMinX(layoutAttributes.frame));
                    maxXForThumbnails = MAX(maxXForThumbnails, CGRectGetMaxX(layoutAttributes.frame));
                    
                    layoutAttributes.zIndex = 0;
                    break;
                }
                case CinematicEditTimelineItemModelTypeDetections: {
                    CMTimeRange timeRange = itemModel.timeRange;
                    assert(CMTIMERANGE_IS_VALID(timeRange));
                    
                    CGFloat xOffset = halfBoundsWidth + CMTimeConvertScale(timeRange.start, pixelsForSecond, kCMTimeRoundingMethod_Default).value;
                    CGFloat width = CMTimeConvertScale(timeRange.duration, pixelsForSecond, kCMTimeRoundingMethod_Default).value;
                    
                    layoutAttributes.frame = CGRectMake(xOffset,
                                                        yOffset,
                                                        width,
                                                        50.);
                    maxXOffset = MAX(xOffset + width, maxXOffset);
                    
                    minXForThumbnails = MIN(minXForThumbnails, CGRectGetMinX(layoutAttributes.frame));
                    maxXForThumbnails = MAX(maxXForThumbnails, CGRectGetMaxX(layoutAttributes.frame));
                    
                    layoutAttributes.zIndex = 0;
                    break;
                }
                case CinematicEditTimelineItemModelTypeDecision: {
                    CMTimeRange timeRange = itemModel.timeRange;
                    assert(CMTIMERANGE_IS_VALID(timeRange));
                    
                    CGFloat xOffset = halfBoundsWidth + CMTimeConvertScale(timeRange.start, pixelsForSecond, kCMTimeRoundingMethod_Default).value;
                    CGFloat width = CMTimeConvertScale(timeRange.duration, pixelsForSecond, kCMTimeRoundingMethod_Default).value;
                    
                    layoutAttributes.frame = CGRectMake(xOffset,
                                                        yOffset,
                                                        width,
                                                        20.);
                    maxXOffset = MAX(xOffset + width, maxXOffset);
                    
                    layoutAttributes.zIndex = 2;
                    break;
                }
                default:
                    abort();
            }
            
            cachedLayoutAttributesByIndexPath[indexPath] = layoutAttributes;
        }
        
        switch (sectionModel.type) {
            case CinematicEditTimelineSectionModelTypeVideoTrack: {
                if ((minXForThumbnails != CGFLOAT_MAX) and (maxXForThumbnails != CGFLOAT_MIN)) {
                    CGFloat preferredVideoThumbnailWidth = 70.;
                    NSInteger thumbnailCount = ceil((maxXForThumbnails - minXForThumbnails) / preferredVideoThumbnailWidth);
                    CGFloat videoThumbnailWidth = (maxXForThumbnails - minXForThumbnails) / thumbnailCount;
                    
                    for (NSInteger thumbnailIndex : std::views::iota(0, thumbnailCount)) {
                        CGFloat xOffset = minXForThumbnails + (videoThumbnailWidth * thumbnailIndex);
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:thumbnailIndex inSection:sectionIndex];
                        CinematicEditTimelineCollectionViewLayoutAttributes *layoutAttributes = [CinematicEditTimelineCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:CinematicEditTimelineCollectionViewLayoutVideoThumbnailSupplementaryElementKind withIndexPath:indexPath];
                        layoutAttributes.frame = CGRectMake(xOffset, yOffset, videoThumbnailWidth, 50.);
                        layoutAttributes.thumbnailPresentationTrackID = sectionModel.trackID;
                        layoutAttributes.thumbnailPresentationTime = [self timeFromContentOffset:CGPointMake(xOffset - halfBoundsWidth, yOffset)];
                        layoutAttributes.zIndex = 1;
                        
                        cachedVideoThumbnailLayoutAttibutesByIndexPath[indexPath] = layoutAttributes;
                    }
                }
                
                //
                
                yOffset += 50.;
                break;
            }
            case CinematicEditTimelineSectionModelTypeDisparityTrack: {
                if ((minXForThumbnails != CGFLOAT_MAX) and (maxXForThumbnails != CGFLOAT_MIN)) {
                    CGFloat preferredVideoThumbnailWidth = 70.;
                    NSInteger thumbnailCount = ceil((maxXForThumbnails - minXForThumbnails) / preferredVideoThumbnailWidth);
                    CGFloat videoThumbnailWidth = (maxXForThumbnails - minXForThumbnails) / thumbnailCount;
                    
                    for (NSInteger thumbnailIndex : std::views::iota(0, thumbnailCount)) {
                        CGFloat xOffset = minXForThumbnails + (videoThumbnailWidth * thumbnailIndex);
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:thumbnailIndex inSection:sectionIndex];
                        CinematicEditTimelineCollectionViewLayoutAttributes *layoutAttributes = [CinematicEditTimelineCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:CinematicEditTimelineCollectionViewLayoutDisparityThumbnailSupplementaryElementKind withIndexPath:indexPath];
                        layoutAttributes.frame = CGRectMake(xOffset, yOffset, videoThumbnailWidth, 50.);
                        layoutAttributes.thumbnailPresentationTrackID = sectionModel.trackID;
                        layoutAttributes.thumbnailPresentationTime = [self timeFromContentOffset:CGPointMake(xOffset - halfBoundsWidth, yOffset)];
                        layoutAttributes.zIndex = 1;
                        
                        cachedDisparityThumbnailLayoutAttibutesByIndexPath[indexPath] = layoutAttributes;
                    }
                }
                
                //
                
                yOffset += 50.;
                break;
            }
            case CinematicEditTimelineSectionModelTypeDetectionTrack: {
                if ((minXForThumbnails != CGFLOAT_MAX) and (maxXForThumbnails != CGFLOAT_MIN)) {
                    CGFloat preferredVideoThumbnailWidth = 70.;
                    NSInteger thumbnailCount = ceil((maxXForThumbnails - minXForThumbnails) / preferredVideoThumbnailWidth);
                    CGFloat videoThumbnailWidth = (maxXForThumbnails - minXForThumbnails) / thumbnailCount;
                    
                    for (NSInteger thumbnailIndex : std::views::iota(0, thumbnailCount)) {
                        CGFloat xOffset = minXForThumbnails + (videoThumbnailWidth * thumbnailIndex);
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:thumbnailIndex inSection:sectionIndex];
                        CinematicEditTimelineCollectionViewLayoutAttributes *layoutAttributes = [CinematicEditTimelineCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:CinematicEditTimelineCollectionViewLayoutDetectionThumbnailSupplementaryElementKind withIndexPath:indexPath];
                        layoutAttributes.frame = CGRectMake(xOffset, yOffset, videoThumbnailWidth, 50.);
                        layoutAttributes.thumbnailPresentationDetectionTrackID = sectionModel.detectionTrackID;
                        layoutAttributes.thumbnailPresentationTrackID = sectionModel.trackID;
                        layoutAttributes.thumbnailPresentationTime = [self timeFromContentOffset:CGPointMake(xOffset - halfBoundsWidth, yOffset)];
                        layoutAttributes.zIndex = 1;
                        
                        cachedVideoThumbnailLayoutAttibutesByIndexPath[indexPath] = layoutAttributes;
                    }
                }
                
                //
                
                yOffset += 50.;
                break;
            }
            default:
                break;
        }
    }
    
    self.cachedLayoutAttributesByIndexPath = cachedLayoutAttributesByIndexPath;
    [cachedLayoutAttributesByIndexPath release];
    self.cachedVideoThumbnailLayoutAttibutesByIndexPath = cachedVideoThumbnailLayoutAttibutesByIndexPath;
    [cachedVideoThumbnailLayoutAttibutesByIndexPath release];
    self.cachedDisparityThumbnailLayoutAttibutesByIndexPath = cachedDisparityThumbnailLayoutAttibutesByIndexPath;
    [cachedDisparityThumbnailLayoutAttibutesByIndexPath release];
    self.cachedDetectionThumbnailLayoutAttibutesByIndexPath = cachedDetectionThumbnailLayoutAttibutesByIndexPath;
    [cachedDetectionThumbnailLayoutAttibutesByIndexPath release];
    
    self.collectionViewContentSize = CGSizeMake(maxXOffset + halfBoundsWidth, yOffset);
    
    //
    
    self.playheadLayoutAttributes = [self _makePlayheadLayoutAttributes];
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<CinematicEditTimelineCollectionViewLayoutAttributes *> *results = [NSMutableArray array];
    
    for (CinematicEditTimelineCollectionViewLayoutAttributes *layoutAttributes in self.cachedLayoutAttributesByIndexPath.allValues) {
        if (CGRectIntersectsRect(layoutAttributes.frame, rect)) {
            [results addObject:layoutAttributes];
        }
    }
    
    for (CinematicEditTimelineCollectionViewLayoutAttributes *layoutAttributes in self.cachedDisparityThumbnailLayoutAttibutesByIndexPath.allValues) {
        if (CGRectIntersectsRect(layoutAttributes.frame, rect)) {
            [results addObject:layoutAttributes];
        }
    }
    
    for (CinematicEditTimelineCollectionViewLayoutAttributes *layoutAttributes in self.cachedVideoThumbnailLayoutAttibutesByIndexPath.allValues) {
        if (CGRectIntersectsRect(layoutAttributes.frame, rect)) {
            [results addObject:layoutAttributes];
        }
    }
    
    for (CinematicEditTimelineCollectionViewLayoutAttributes *layoutAttributes in self.cachedDetectionThumbnailLayoutAttibutesByIndexPath.allValues) {
        if (CGRectIntersectsRect(layoutAttributes.frame, rect)) {
            [results addObject:layoutAttributes];
        }
    }
    
    if (CinematicEditTimelineCollectionViewLayoutAttributes *playheadLayoutAttributes = self.playheadLayoutAttributes) {
        [results addObject:playheadLayoutAttributes];
    }
    
    return results;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.cachedLayoutAttributesByIndexPath[indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:CinematicEditTimelineCollectionViewLayoutVideoThumbnailSupplementaryElementKind]) {
        return self.cachedVideoThumbnailLayoutAttibutesByIndexPath[indexPath];
    } else if ([elementKind isEqualToString:CinematicEditTimelineCollectionViewLayoutDetectionThumbnailSupplementaryElementKind]) {
        return self.cachedDetectionThumbnailLayoutAttibutesByIndexPath[indexPath];
    } else if ([elementKind isEqual:CinematicEditTimelineCollectionViewLayoutDisparityThumbnailSupplementaryElementKind]) {
        return self.cachedDisparityThumbnailLayoutAttibutesByIndexPath[indexPath];
    }
    
    abort();
}

- (UICollectionViewLayoutAttributes *) layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:NSStringFromClass([CinematicEditTimelinePlayheadView class])]) {
        if ([indexPath isEqual:[NSIndexPath indexPathForItem:0 inSection:0]]) {
            return self.playheadLayoutAttributes;
        }
    }
    
    abort();
}

- (void)_setCollectionView:(UICollectionView *)collectionView {
    objc_super superInfo = { self, [self class] };
    reinterpret_cast<void (*)(objc_super *, SEL, id)>(objc_msgSendSuper2)(&superInfo, _cmd, collectionView);
    reinterpret_cast<void (*)(id, SEL, BOOL, BOOL)>(objc_msgSend)(collectionView, sel_registerName("_setDefaultAlwaysBounceVertical:horizontal:"), NO, YES);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (CinematicEditTimelineCollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    auto context = static_cast<CinematicEditTimelineCollectionViewLayoutInvalidationContext *>([super invalidationContextForBoundsChange:newBounds]);
    CGRect oldBounds = self.collectionView.bounds;
    context.oldBounds = oldBounds;
    context.newBounds = newBounds;
    
    return context;
}

- (void)invalidateLayoutWithContext:(CinematicEditTimelineCollectionViewLayoutInvalidationContext *)context {
    CGRect oldBounds = context.oldBounds;
    CGRect newBounds = context.newBounds;
    
    if ((CGRectGetMinX(oldBounds) != CGRectGetMinX(newBounds)) or (CGRectGetWidth(oldBounds) != CGRectGetWidth(newBounds))) {
        self.playheadLayoutAttributes = [self _makePlayheadLayoutAttributes];
        [context invalidateDecorationElementsOfKind:NSStringFromClass([CinematicEditTimelinePlayheadView class]) atIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    }
    
    [super invalidateLayoutWithContext:context];
}

- (CinematicEditTimelineCollectionViewLayoutAttributes * _Nullable)_makePlayheadLayoutAttributes {
    UICollectionView *collectionView = self.collectionView;
    if (collectionView == nil) return nil;
    
    CinematicEditTimelineCollectionViewLayoutAttributes *playheadLayoutAttributes = [CinematicEditTimelineCollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:NSStringFromClass([CinematicEditTimelinePlayheadView class]) withIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    playheadLayoutAttributes.frame = CGRectMake(CGRectGetMinX(collectionView.bounds) + CGRectGetWidth(collectionView.bounds) * 0.5 - 1.,
                                                CGRectGetMinY(collectionView.bounds),
                                                2.,
                                                CGRectGetHeight(collectionView.bounds));
    playheadLayoutAttributes.zIndex = 3;
    
    return playheadLayoutAttributes;
}

@end

#endif
