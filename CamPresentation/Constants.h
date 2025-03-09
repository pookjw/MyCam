//
//  Constants.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/19/24.
//

#import <Foundation/Foundation.h>
#import <CamPresentation/Extern.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSString * const CPSceneActivityType;
CP_EXTERN NSString * const CPSceneTypeKey;
CP_EXTERN NSString * const CPARPlayerScene;
CP_EXTERN NSErrorDomain const CamPresentationErrorDomain;

typedef NS_ERROR_ENUM(CamPresentationErrorDomain, CPErrorCode) {
    CPErrorCodeCancelled = 1
};

NS_ASSUME_NONNULL_END
