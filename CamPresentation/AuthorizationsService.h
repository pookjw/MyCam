//
//  AuthorizationsService.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/31/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AuthorizationsService : NSObject
- (void)requestAuthorizationsWithCompletionHandler:(void (^ _Nullable)(BOOL authorized))completionHandler;
@end

NS_ASSUME_NONNULL_END
