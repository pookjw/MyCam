//
//  CinematicEditTimelineSectionModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicEditTimelineSectionModel.h>

@implementation CinematicEditTimelineSectionModel

- (instancetype)initWithType:(CinematicEditTimelineSectionModelType)type {
    if (self = [super init]) {
        _type = type;
    }
    
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    
    if (![other isKindOfClass:[CinematicEditTimelineSectionModel class]]) {
        return NO;
    }
    
    auto casted = static_cast<CinematicEditTimelineSectionModel *>(other);
    
    return _type == casted->_type;
}

- (NSUInteger)hash {
    return _type;
}

@end
