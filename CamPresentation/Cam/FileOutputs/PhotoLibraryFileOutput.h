//
//  PhotoLibraryFileOutput.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/BaseFileOutput.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoLibraryFileOutput : BaseFileOutput
@property (retain, nonatomic, readonly) PHPhotoLibrary *photoLibrary;
- (instancetype)initWithPhotoLibrary:(PHPhotoLibrary *)photoLibrary;
@end

NS_ASSUME_NONNULL_END
