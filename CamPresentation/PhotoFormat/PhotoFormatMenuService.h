//
//  PhotoFormatMenuService.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/18/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/PhotoFormatModel.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@class PhotoFormatMenuService;
@protocol PhotoFormatMenuDelegate <NSObject>
- (void)photoFormatMenuElementsDidChange:(PhotoFormatMenuService *)photoFormatMenu;
@end

@interface PhotoFormatMenuService : NSObject
@property (copy, nonatomic, readonly) PhotoFormatModel *photoFormatModel;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPhotoFormatModel:(PhotoFormatModel *)photoFormatModel captureService:(CaptureService *)captureService delegate:(id<PhotoFormatMenuDelegate>)delegate;
- (void)menuElementsWithCompletionHandler:(void (^ _Nullable)(NSArray<__kindof UIMenuElement *> *menuElements))completionHandler;
@end

NS_ASSUME_NONNULL_END
