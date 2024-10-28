//
//  NSURL+CP.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/29/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (CP)
+ (NSURL *)cp_processTemporaryURLByCreatingDirectoryIfNeeded:(BOOL)createDirectory;
@end

NS_ASSUME_NONNULL_END
