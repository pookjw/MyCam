//
//  CinematicEditTimelineCollectionViewLayout.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicEditTimelineCollectionViewLayout.h>
#import <CamPresentation/CinematicEditTimelineCollectionViewLayoutAttributes.h>
#include <ranges>
#import <CamPresentation/CinematicEditTimelineSectionModel.h>
#import <CamPresentation/CinematicEditTimelineItemModel.h>

@interface CinematicEditTimelineCollectionViewLayout ()
@property (assign, nonatomic, setter=_setCollectionViewContentSize:) CGSize collectionViewContentSize;
@property (copy, nonatomic, nullable, getter=_cachedLayoutAttributesByIndexPath, setter=_setCachedLayoutAttributesByIndexPath:) NSDictionary<NSIndexPath *, CinematicEditTimelineCollectionViewLayoutAttributes *> *cachedLayoutAttributesByIndexPath;
@end

@implementation CinematicEditTimelineCollectionViewLayout

+ (Class)layoutAttributesClass {
    return [CinematicEditTimelineCollectionViewLayoutAttributes class];
}

- (void)dealloc {
    [_cachedLayoutAttributesByIndexPath release];
    [super dealloc];
}

- (void)prepareLayout {
    [super prepareLayout];
    
    UICollectionView *collectionView = self.collectionView;
    if (collectionView == nil) {
        self.cachedLayoutAttributesByIndexPath = nil;
        return;
    }
    
    // TODO
    self.collectionViewContentSize = collectionView.bounds.size;
    
    auto dataSource = static_cast<UICollectionViewDiffableDataSource<CinematicEditTimelineSectionModel *, CinematicEditTimelineItemModel *> *>(collectionView.dataSource);
    assert([dataSource isKindOfClass:[UICollectionViewDiffableDataSource class]]);
    
    NSMutableDictionary<NSIndexPath *, CinematicEditTimelineCollectionViewLayoutAttributes *> *cachedLayoutAttributesByIndexPath = [NSMutableDictionary new];
    CGFloat yOffset = 0.;
    CGFloat pixelsForSecond = 30.;
    
    for (NSInteger sectionIndex : std::views::iota(0, collectionView.numberOfSections)) {
        CinematicEditTimelineSectionModel *sectionModel = [dataSource sectionIdentifierForIndex:sectionIndex];
        assert(sectionModel != nil);
        NSInteger numberOfItems = [collectionView numberOfItemsInSection:sectionIndex];
        
        for (NSInteger itemIndex : std::views::iota(0, numberOfItems)) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
            CinematicEditTimelineItemModel *itemModel = [dataSource itemIdentifierForIndexPath:indexPath];
            assert(itemModel != nil);
            
            CinematicEditTimelineCollectionViewLayoutAttributes *layoutAttributes = [CinematicEditTimelineCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            
            switch (itemModel.type) {
                case CinematicEditTimelineItemModelTypeVideoTrack: {
                    CMTimeRange timeRange = sectionModel.timeRange;
                    assert(CMTIMERANGE_IS_VALID(timeRange));
                    layoutAttributes.frame = CGRectMake(CMTimeConvertScale(timeRange.start, pixelsForSecond, kCMTimeRoundingMethod_Default).value,
                                                        yOffset,
                                                        CMTimeConvertScale(timeRange.duration, pixelsForSecond, kCMTimeRoundingMethod_Default).value,
                                                        50.);
                    break;
                }
                case CinematicEditTimelineItemModelTypeDetections: {
                    CMTimeRange timeRange = itemModel.timeRange;
                    assert(CMTIMERANGE_IS_VALID(timeRange));
                    CMTimeRangeShow(timeRange);
                    layoutAttributes.frame = CGRectMake(CMTimeConvertScale(timeRange.start, pixelsForSecond, kCMTimeRoundingMethod_Default).value,
                                                        yOffset,
                                                        CMTimeConvertScale(timeRange.duration, pixelsForSecond, kCMTimeRoundingMethod_Default).value,
                                                        50.);
                    break;
                }
                case CinematicEditTimelineItemModelTypeDecision: {
                    CMTimeRange timeRange = itemModel.timeRange;
                    assert(CMTIMERANGE_IS_VALID(timeRange));
                    layoutAttributes.frame = CGRectMake(CMTimeConvertScale(timeRange.start, pixelsForSecond, kCMTimeRoundingMethod_Default).value,
                                                        yOffset,
                                                        CMTimeConvertScale(timeRange.duration, pixelsForSecond, kCMTimeRoundingMethod_Default).value,
                                                        20.);
                    break;
                }
                default:
                    abort();
            }
            
            cachedLayoutAttributesByIndexPath[indexPath] = layoutAttributes;
        }
        
        switch (sectionModel.type) {
            case CinematicEditTimelineSectionModelTypeVideoTrack:
                yOffset += 50.;
                break;
            case CinematicEditTimelineSectionModelTypeDetectionTrack:
                yOffset += 50.;
                break;
            default:
                break;
        }
    }
    
    self.cachedLayoutAttributesByIndexPath = cachedLayoutAttributesByIndexPath;
    [cachedLayoutAttributesByIndexPath release];
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<CinematicEditTimelineCollectionViewLayoutAttributes *> *results = [NSMutableArray array];
    
    for (CinematicEditTimelineCollectionViewLayoutAttributes *layoutAttributes in self.cachedLayoutAttributesByIndexPath.allValues) {
        if (CGRectIntersectsRect(layoutAttributes.frame, rect)) {
            [results addObject:layoutAttributes];
        }
    }
    
    return results;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.cachedLayoutAttributesByIndexPath[indexPath];
}

@end
