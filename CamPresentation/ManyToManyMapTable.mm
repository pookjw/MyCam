//
//  ManyToManyMapTable.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/14/25.
//

#import <CamPresentation/ManyToManyMapTable.h>
#include <objc/message.h>
#include <objc/runtime.h>

@interface ManyToManyMapTable () {
@protected NSMapTable<id, NSMutableArray<id> *> *_firstToSecondsMap;
@protected NSMapTable<id, NSMutableArray<id> *> *_secondToFirstsMap;
}
@end

@implementation ManyToManyMapTable

- (instancetype)init {
    if (self = [super init]) {
        _firstToSecondsMap = [[NSMapTable strongToStrongObjectsMapTable] retain];
        _secondToFirstsMap = [[NSMapTable strongToStrongObjectsMapTable] retain];
    }
    
    return self;
}

- (void)dealloc {
    [_firstToSecondsMap release];
    [_secondToFirstsMap release];
    [super dealloc];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    ManyToManyMapTable *copy = [[[self class] allocWithZone:zone] init];
    
    copy->_firstToSecondsMap = [[NSMapTable strongToStrongObjectsMapTable] retain];
    for (id firstObject in _firstToSecondsMap.keyEnumerator) {
        NSMutableArray<id> *secondObjects = [_firstToSecondsMap objectForKey:firstObject];
        NSMutableArray<id> *copiedSecondObjects = [secondObjects mutableCopy];
        [copy->_firstToSecondsMap setObject:copiedSecondObjects forKey:firstObject];
        [copiedSecondObjects release];
    }
    
    copy->_secondToFirstsMap = [[NSMapTable strongToStrongObjectsMapTable] retain];
    for (id secondObject in _secondToFirstsMap.keyEnumerator) {
        NSMutableArray<id> *firstObjects = [_secondToFirstsMap objectForKey:secondObject];
        NSMutableArray<id> *copiedFirstObjects = [firstObjects mutableCopy];
        [copy->_secondToFirstsMap setObject:copiedFirstObjects forKey:secondObject];
        [copiedFirstObjects release];
    }
    
    return copy;
}

- (NSArray *)firstObjects {
    return reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(_firstToSecondsMap, sel_registerName("allKeys"));
}

- (NSArray *)secondObjects {
    return reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(_secondToFirstsMap, sel_registerName("allKeys"));
}

- (NSArray *)secondObjectsForFirstObject:(id)firstObject {
    return [ManyToManyMapTable _BObjectsForAObject:firstObject AToBMapTable:_firstToSecondsMap BToAMapTable:_secondToFirstsMap];
}

- (void)setSecondObjects:(NSArray *)secondObjects forFirstObject:(id)firstObject {
    [ManyToManyMapTable _setBObjects:secondObjects forAObject:firstObject AToBMapTable:_firstToSecondsMap BToAMapTable:_secondToFirstsMap];
}

- (void)addSecondObjects:(NSArray *)secondObjects forFirstObject:(id)firstObject {
    [ManyToManyMapTable _addBObjects:secondObjects forAObject:firstObject AToBMapTable:_firstToSecondsMap BToAMapTable:_secondToFirstsMap];
}

- (void)removeSecondObjects:(NSArray *)secondObjects forFirstObject:(id)firstObject {
    [ManyToManyMapTable _removeBObjects:secondObjects forAObject:firstObject AToBMapTable:_firstToSecondsMap BToAMapTable:_secondToFirstsMap];
}

- (NSArray *)firstObjectsForSecondObject:(id)secondObject {
    return [ManyToManyMapTable _BObjectsForAObject:secondObject AToBMapTable:_secondToFirstsMap BToAMapTable:_firstToSecondsMap];
}

- (void)setFirstObjects:(NSArray *)firstObjects forSecondObject:(id)secondObject {
    [ManyToManyMapTable _setBObjects:firstObjects forAObject:secondObject AToBMapTable:_secondToFirstsMap BToAMapTable:_firstToSecondsMap];
}

- (void)addFirstObjects:(NSArray *)firstObjects forSecondObject:(id)secondObject {
    [ManyToManyMapTable _addBObjects:firstObjects forAObject:secondObject AToBMapTable:_secondToFirstsMap BToAMapTable:_firstToSecondsMap];
}

- (void)removeFirstObjects:(NSArray *)firstObjects forSecondObject:(id)secondObject {
    [ManyToManyMapTable _removeBObjects:firstObjects forAObject:secondObject AToBMapTable:_secondToFirstsMap BToAMapTable:_firstToSecondsMap];
}

+ (void)_validateWithAToBMapTable:(NSMapTable *)AToBMapTable BToAMapTable:(NSMapTable *)BToAMapTable {
    NSSet *AToBObjects = [ManyToManyMapTable _allObjectsFromMapTable:AToBMapTable];
    NSSet *BToAObjects = [ManyToManyMapTable _allObjectsFromMapTable:BToAMapTable];
    assert([AToBObjects isEqualToSet:BToAObjects]);
    [AToBObjects release];
    [BToAObjects release];
}

+ (NSSet *)_allObjectsFromMapTable:(NSMapTable *)mapTable NS_RETURNS_RETAINED {
    NSMutableSet *results = [[NSMutableSet alloc] init];
    
    NSArray *allKeys = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(mapTable, sel_registerName("allKeys"));
    [results addObjectsFromArray:allKeys];
    
    NSArray<NSArray *> *allValues = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(mapTable, sel_registerName("allValues"));
    for (NSArray *value in allValues) {
        [results addObjectsFromArray:value];
    }
    
    return results;
}

+ (NSArray *)_BObjectsForAObject:(id)AObject AToBMapTable:(NSMapTable *)AToBMapTable BToAMapTable:(NSMapTable *)BToAMapTable {
    [self _validateWithAToBMapTable:AToBMapTable BToAMapTable:BToAMapTable];
    return [AToBMapTable objectForKey:AObject];
}

+ (void)_setBObjects:(NSArray * _Nullable)BObjects forAObject:(id)AObject AToBMapTable:(NSMapTable *)AToBMapTable BToAMapTable:(NSMapTable *)BToAMapTable {
    assert(![BObjects containsObject:AObject]);
    
    {
        if (BObjects.count == 0) {
            [AToBMapTable removeObjectForKey:AObject];
        } else {
            NSMutableArray *mutableBObjects = [BObjects mutableCopy];
            [AToBMapTable setObject:mutableBObjects forKey:AObject];
            [mutableBObjects release];
        }
    }
    
    {
        NSMutableArray *newlyAddedBObjects;
        if (BObjects == nil) {
            newlyAddedBObjects = [[NSMutableArray alloc] init];
        } else {
            newlyAddedBObjects = [BObjects mutableCopy];
        }
        
        NSMutableArray *emptyBObjects = [[NSMutableArray alloc] init];
        
        for (id BObject in BToAMapTable.keyEnumerator) {
            [newlyAddedBObjects removeObject:BObject];
            
            NSMutableArray *existingAObjects = [BToAMapTable objectForKey:BObject];
            
            if ([BObjects containsObject:BObject]) {
                if (![existingAObjects containsObject:AObject]) {
                    [existingAObjects addObject:AObject];
                }
            } else {
                if ([existingAObjects containsObject:AObject]) {
                    [existingAObjects removeObject:AObject];
                    
                    if (existingAObjects.count == 0) {
                        [emptyBObjects addObject:BObject];
                    }
                }
            }
        }
        
        for (id BObject in newlyAddedBObjects) {
            NSMutableArray *AObjects = [[NSMutableArray alloc] initWithObjects:AObject, nil];
            [BToAMapTable setObject:AObjects forKey:BObject];
            [AObjects release];
        }
        [newlyAddedBObjects release];
        
        for (id BObject in emptyBObjects) {
            [BToAMapTable removeObjectForKey:BObject];
        }
        [emptyBObjects release];
    }
    
    [self _validateWithAToBMapTable:AToBMapTable BToAMapTable:BToAMapTable];
}

+ (void)_addBObjects:(NSArray *)BObjects forAObject:(id)AObject AToBMapTable:(NSMapTable *)AToBMapTable BToAMapTable:(NSMapTable *)BToAMapTable {
    assert(![BObjects containsObject:AObject]);
    
    {
        NSMutableArray * _Nullable existingBObjects = [AToBMapTable objectForKey:AObject];
        if (existingBObjects != nil) {
            for (id BObject in BObjects) {
                if (![existingBObjects containsObject:BObject]) {
                    [existingBObjects addObject:BObject];
                }
            }
        } else {
            NSMutableArray *mutableBObjects = [BObjects mutableCopy];
            [AToBMapTable setObject:mutableBObjects forKey:AObject];
            [mutableBObjects release];
        }
    }
    
    {
        NSMutableArray *newlyAddedBObjects = [BObjects mutableCopy];
        
        for (id BObject in BToAMapTable.keyEnumerator) {
            [newlyAddedBObjects removeObject:BObject];
            
            if ([BObjects containsObject:BObject]) {
                NSMutableArray *existingAObjects = [BToAMapTable objectForKey:BObject];
                if (![existingAObjects containsObject:AObject]) {
                    [existingAObjects addObject:AObject];
                }
            }
        }
        
        for (id BObject in newlyAddedBObjects) {
            NSMutableArray *AObjects = [[NSMutableArray alloc] initWithObjects:AObject, nil];
            [BToAMapTable setObject:AObjects forKey:BObject];
            [AObjects release];
        }
        [newlyAddedBObjects release];
    }
    
    [self _validateWithAToBMapTable:AToBMapTable BToAMapTable:BToAMapTable];
}

+ (void)_removeBObjects:(NSArray *)BObjects forAObject:(id)AObject AToBMapTable:(NSMapTable *)AToBMapTable BToAMapTable:(NSMapTable *)BToAMapTable {
    {
        NSMutableArray * _Nullable existingBObjects = [AToBMapTable objectForKey:AObject];
        if (existingBObjects != nil) {
            for (id BObject in BObjects) {
                if ([existingBObjects containsObject:BObject]) {
                    [existingBObjects removeObject:BObject];
                }
            }
            
            if (existingBObjects.count == 0) {
                [AToBMapTable removeObjectForKey:AObject];
            }
        }
    }
    
    {
        NSMutableArray *emptyBObjects = [NSMutableArray new];
        
        for (id BObject in BToAMapTable.keyEnumerator) {
            NSMutableArray *existingAObjects = [BToAMapTable objectForKey:BObject];
            
            if ([BObjects containsObject:BObject]) {
                if ([existingAObjects containsObject:AObject]) {
                    [existingAObjects removeObject:AObject];
                    
                    if (existingAObjects.count == 0) {
                        [emptyBObjects addObject:BObject];
                    }
                }
            }
        }
        
        for (id BObject in emptyBObjects) {
            [BToAMapTable removeObjectForKey:BObject];
        }
        [emptyBObjects release];
    }
    
    [self _validateWithAToBMapTable:AToBMapTable BToAMapTable:BToAMapTable];
}

@end
