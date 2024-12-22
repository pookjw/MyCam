//
//  ImageVisionViewModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/21/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <Vision/Vision.h>
#import <CamPresentation/Extern.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSNotificationName const ImageVisionViewModelDidChangeObservationsNotificationName;

@interface ImageVisionViewModel : NSObject

- (void)requestsWithHandler:(void (^)(NSArray<__kindof VNRequest *> *requests))completionHandler;
- (NSProgress *)addRequest:(__kindof VNRequest *)request completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)removeRequest:(__kindof VNRequest *)request completionHandler:(void (^ _Nullable)(void))completionHandler;

- (void)observationsWithHandler:(void (^)(NSArray<__kindof VNObservation *> *observations))handler;

- (NSProgress *)updateImage:(UIImage *)image completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (NSProgress *)updateImageWithPHAsset:(PHAsset *)asset completionHandler:(void (^ _Nullable)(UIImage * _Nullable image, NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
