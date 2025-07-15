//
//  ManyToManyMapTable.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/14/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ManyToManyMapTable<First, Second> : NSObject <NSCopying>
@property (nonatomic, readonly) NSArray<First> *firstObjects;
@property (nonatomic, readonly) NSArray<Second> *secondObjects;

- (NSArray<Second> * _Nullable)secondObjectsForFirstObject:(First)firstObject;
- (void)setSecondObjects:(NSArray<Second> * _Nullable)secondObjects forFirstObject:(First)firstObject;
- (void)addSecondObjects:(NSArray<Second> *)secondObjects forFirstObject:(First)firstObject;
- (void)removeSecondObjects:(NSArray<Second> *)secondObjects forFirstObject:(First)firstObject;

- (NSArray<First> * _Nullable)firstObjectsForSecondObject:(Second)secondObject;
- (void)setFirstObjects:(NSArray<First> * _Nullable)firstObjects forSecondObject:(Second)secondObject;
- (void)addFirstObjects:(NSArray<First> *)firstObjects forSecondObject:(Second)secondObject;
- (void)removeFirstObjects:(NSArray<First> *)firstObjects forSecondObject:(Second)secondObject;
@end

NS_ASSUME_NONNULL_END
