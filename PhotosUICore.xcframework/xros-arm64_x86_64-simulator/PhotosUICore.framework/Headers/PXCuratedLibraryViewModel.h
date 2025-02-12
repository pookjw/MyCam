#import <PhotosUIFoundation/PXObservable.h>
#import <PhotosUICore/PXCuratedLibraryAssetsDataSourceManagerDelegate.h>
#import <PhotosUICore/PXCuratedLibraryViewConfiguration.h>
#import <PhotosUICore/PXCuratedLibraryAssetsDataSourceManagerConfiguration.h>
#import <PhotosUICore/PXMediaProvider.h>
#import <PhotosUICore/PXCuratedLibraryLayoutSpecManager.h>
#import <PhotosUICore/PXCuratedLibraryStyleGuide.h>
#import <PhotosUICore/PXCuratedLibraryViewModelPresenter.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXCuratedLibraryViewModel : PXObservable <PXCuratedLibraryAssetsDataSourceManagerDelegate>
@property (readonly, nonatomic) NSArray<id<PXCuratedLibraryViewModelPresenter>> *presenters;
@property (readonly, nonatomic) NSArray *views;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfiguration:(PXCuratedLibraryViewConfiguration *)configuration assetsDataSourceManagerConfiguration:(PXCuratedLibraryAssetsDataSourceManagerConfiguration *)assetsDataSourceManagerConfiguration zoomLevel:(NSInteger)zoomLevel mediaProvider:(PXMediaProvider *)mediaProvider specManager:(PXCuratedLibraryLayoutSpecManager *)specManager styleGuide:(PXCuratedLibraryStyleGuide *)styleGuide;
- (void)addPresenter:(id<PXCuratedLibraryViewModelPresenter>)presenter;
- (void)removePresenter:(id<PXCuratedLibraryViewModelPresenter>)presenter;
- (void)addView:(id)view;
- (void)removeView:(id)view;
@end

NS_ASSUME_NONNULL_END