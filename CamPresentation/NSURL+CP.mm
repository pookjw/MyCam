//
//  NSURL+CP.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/29/24.
//

#import <CamPresentation/NSURL+CP.h>

@implementation NSURL (CP)

+ (NSURL *)cp_processTemporaryURLByCreatingDirectoryIfNeeded:(BOOL)createDirectory {
    NSURL *tmpURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSString *processName = NSProcessInfo.processInfo.processName;
    NSURL *processDirectoryURL = [tmpURL URLByAppendingPathComponent:processName isDirectory:YES];
    
    BOOL isDirectory;
    if (![NSFileManager.defaultManager fileExistsAtPath:processDirectoryURL.path isDirectory:&isDirectory]) {
        NSError * _Nullable error = nil;
        [NSFileManager.defaultManager createDirectoryAtURL:processDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error];
        assert(error == nil);
        isDirectory = YES;
    }
    assert(isDirectory);
    
    return processDirectoryURL;
}

@end
