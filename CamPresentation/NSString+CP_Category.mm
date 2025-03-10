//
//  NSString+CP_Category.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/10/25.
//

#import <CamPresentation/NSString+CP_Category.h>

@implementation NSString (CP_Category)

- (NSString *)cp_reversedString {
    NSInteger length = self.length;
    NSMutableString *output = [[NSMutableString alloc] initWithCapacity:length];
    
    [self enumerateSubstringsInRange:NSMakeRange(0, length) options:NSStringEnumerationByComposedCharacterSequences | NSStringEnumerationReverse usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        [output appendString:substring];
    }];
    
    return [output autorelease];
}

@end
