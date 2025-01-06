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
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSNotificationName const ImageVisionViewModelDidChangeObservationsNotificationName;

__attribute__((objc_direct_members))
@interface ImageVisionViewModel : NSObject
@property (assign, atomic, readonly, getter=isLoading) BOOL loading;

- (NSProgress *)addRequest:(__kindof VNRequest *)request completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)removeRequest:(__kindof VNRequest *)request completionHandler:(void (^ _Nullable)(void))completionHandler;
- (NSProgress *)updateRequest:(__kindof VNRequest *)request completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;

- (NSProgress *)updateImage:(UIImage *)image completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (NSProgress *)updateImageWithPHAsset:(PHAsset *)asset completionHandler:(void (^ _Nullable)(UIImage * _Nullable image, NSError * _Nullable error))completionHandler;
- (NSProgress *)updateWithSampleBuffer:(CMSampleBufferRef)sampleBuffer completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;

- (void)getValuesWithCompletionHandler:(void (^)(NSArray<__kindof VNRequest *> *requests, NSArray<__kindof VNObservation *> *observations, UIImage * _Nullable image))completionHandler;

- (NSProgress *)computeDistanceWithPHAsset:(PHAsset *)asset toFeaturePrintObservation:(VNFeaturePrintObservation *) featurePrint withRequest:(__kindof VNRequest *)request completionHandler:(void (^)(float distance, VNFeaturePrintObservation * _Nullable observationFromAsset, NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
