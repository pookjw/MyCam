//
//  ImageVisionViewModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/21/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <Vision/Vision.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageVisionViewModel : NSObject
@property (retain, nonatomic, readonly) dispatch_queue_t queue;

@property (copy, nonatomic, readonly) NSArray<__kindof VNRequest *> *queue_requests;
- (NSProgress *)queue_addRequest:(__kindof VNRequest *)request completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)queue_removeRequest:(__kindof VNRequest *)request;

- (NSProgress *)queue_updateImage:(UIImage *)image completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (NSProgress *)queue_updateImageWithPHAsset:(PHAsset *)asset completionHandler:(void (^ _Nullable)(UIImage * _Nullable image, NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
