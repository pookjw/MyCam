//
//  ImageFiltersViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/10/25.
//

#import <CamPresentation/ImageFiltersViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CoreImage/CoreImage.h>

@interface ImageFiltersViewController ()

@end

@implementation ImageFiltersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUInteger count = 0;
    
    NSArray<NSString *> *allCategories = reinterpret_cast<id (*)(id, SEL, BOOL)>(objc_msgSend)([CIFilter class], sel_registerName("allCategories:"), YES);
    for (NSString *category in allCategories) {
        NSArray<NSString *> *filterNames = [CIFilter filterNamesInCategory:category];
        for (NSString *filterName in filterNames) {
            NSLog(@"%@ -> %@", category, filterName);
            count += 1;
        }
    }
    
    NSLog(@"%ld", count);
}

@end
