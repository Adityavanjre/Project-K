// Copyright (c) 2025 ByteDance Ltd. and/or its affiliates
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import <RxCoreComponents/metamacros.h>

#ifndef RxTuplePack
    #define RxTuplePack(...) \
        RxTuplePack_(__VA_ARGS__)
#endif

#ifndef RxTupleUnpack
    #define RxTupleUnpack(...) \
        RxTupleUnpack_(__VA_ARGS__)
#endif

@class RxTwoTuple<__covariant First, __covariant Second>;
@class RxThreeTuple<__covariant First, __covariant Second, __covariant Third>;
@class RxFourTuple<__covariant First, __covariant Second, __covariant Third, __covariant Fourth>;
@class RxFiveTuple<__covariant First, __covariant Second, __covariant Third, __covariant Fourth, __covariant Fifth>;

NS_ASSUME_NONNULL_BEGIN

@interface RxTupleNull : NSObject <NSCopying, NSCoding>

+ (instancetype)null;

@end

@interface RxTuple : NSObject <NSCopying, NSCoding, NSFastEnumeration>

@property (assign, nonatomic, readonly) NSUInteger count;

/// These properties all return the object at that index or nil if the number of
/// objects is less than the index.
@property (strong, nonatomic, nullable, readonly) id first;
@property (strong, nonatomic, nullable, readonly) id second;
@property (strong, nonatomic, nullable, readonly) id third;
@property (strong, nonatomic, nullable, readonly) id fourth;
@property (strong, nonatomic, nullable, readonly) id fifth;
@property (strong, nonatomic, nullable, readonly) id last;

/// Creates a new tuple out of the array. Does not convert nulls to nils.
+ (instancetype)tupleWithObjectsFromArray:(NSArray *)array;

/// Creates a new tuple out of the array. If `convert` is YES, it also converts
/// every NSNull to RxTupleNil.
+ (instancetype)tupleWithObjectsFromArray:(NSArray *)array convertNullsToNils:(BOOL)convert;

/// Creates a new tuple with the given objects. Use RxTupleNil to represent
/// nils.
+ (instancetype)tupleWithObjects:(id)object, ... NS_REQUIRES_NIL_TERMINATION;

/// Returns the object at `index` or nil if the object is a RxTupleNil. Unlike
/// NSArray and friends, it's perfectly fine to ask for the object at an index
/// past the tuple's count - 1. It will simply return nil.
- (nullable id)objectAtIndex:(NSUInteger)index;

/// Returns an array of all the objects. RxTupleNils are converted to NSNulls.
- (NSArray *)allObjects;

/// Appends `obj` to the receiver.
///
/// obj - The object to add to the tuple. This argument may be nil.
///
/// Returns a new tuple.
- (__kindof RxTuple *)tupleByAddingObject:(nullable id)obj;

- (nullable id)objectAtIndexedSubscript:(NSUInteger)idx;

@end

/// A tuple with exactly one generic value.
@interface RxOneTuple<__covariant First> : RxTuple

+ (instancetype)tupleWithObjects:(id)object, ... __attribute((unavailable("Use pack: instead.")));

- (RxTwoTuple<First, id> *)tupleByAddingObject:(nullable id)obj;

/// Creates a new tuple with the given values.
+ (RxOneTuple<First> *)pack:(nullable First)first;

@property (strong, nonatomic, nullable, readonly) First first;

@end

/// A tuple with exactly two generic values.
@interface RxTwoTuple<__covariant First, __covariant Second> : RxTuple

+ (instancetype)tupleWithObjects:(id)object, ... __attribute((unavailable("Use pack:: instead.")));

- (RxThreeTuple<First, Second, id> *)tupleByAddingObject:(nullable id)obj;

/// Creates a new tuple with the given value.
+ (RxTwoTuple<First, Second> *)pack:(nullable First)first :(nullable Second)second;

@property (strong, nonatomic, nullable, readonly) First first;
@property (strong, nonatomic, nullable, readonly) Second second;

@end

/// A tuple with exactly three generic values.
@interface RxThreeTuple<__covariant First, __covariant Second, __covariant Third> : RxTuple

+ (instancetype)tupleWithObjects:(id)object, ... __attribute((unavailable("Use pack::: instead.")));

- (RxFourTuple<First, Second, Third, id> *)tupleByAddingObject:(nullable id)obj;

/// Creates a new tuple with the given values.
+ (instancetype)pack:(nullable First)first :(nullable Second)second :(nullable Third)third;

@property (strong, nonatomic, nullable, readonly) First first;
@property (strong, nonatomic, nullable, readonly) Second second;
@property (strong, nonatomic, nullable, readonly) Third third;

@end

/// A tuple with exactly four generic values.
@interface RxFourTuple<__covariant First, __covariant Second, __covariant Third, __covariant Fourth> : RxTuple

+ (instancetype)tupleWithObjects:(id)object, ... __attribute((unavailable("Use pack:::: instead.")));

- (RxFiveTuple<First, Second, Third, Fourth, id> *)tupleByAddingObject:(nullable id)obj;

/// Creates a new tuple with the given values.
+ (instancetype)pack:(nullable First)first :(nullable Second)second :(nullable Third)third :(nullable Fourth)fourth;

@property (strong, nonatomic, nullable, readonly) First first;
@property (strong, nonatomic, nullable, readonly) Second second;
@property (strong, nonatomic, nullable, readonly) Third third;
@property (strong, nonatomic, nullable, readonly) Fourth fourth;

@end

/// A tuple with exactly five generic values.
@interface RxFiveTuple<__covariant First, __covariant Second, __covariant Third, __covariant Fourth, __covariant Fifth> : RxTuple

+ (instancetype)tupleWithObjects:(id)object, ... __attribute((unavailable("Use pack::::: instead.")));

/// Creates a new tuple with the given values.
+ (instancetype)pack:(nullable First)first :(nullable Second)second :(nullable Third)third :(nullable Fourth)fourth :(nullable Fifth)fifth;

@property (strong, nonatomic, nullable, readonly) First first;
@property (strong, nonatomic, nullable, readonly) Second second;
@property (strong, nonatomic, nullable, readonly) Third third;
@property (strong, nonatomic, nullable, readonly) Fourth fourth;
@property (strong, nonatomic, nullable, readonly) Fifth fifth;

@end

#ifndef RxTuplePack_
#define RxTuplePack_(...) \
[RxTuplePack_class_name(__VA_ARGS__) tupleWithObjectsFromArray:@[ metamacro_foreach(RxTuplePack_object_or_ractuplenil,, __VA_ARGS__) ]]
#endif

#ifndef RxTuplePack_object_or_ractuplenil
    #define RxTuplePack_object_or_ractuplenil(INDEX, ARG) \
        (ARG) ?: (id)[RxTupleNull null],
#endif

#define RxTuplePack_class_name(...) \
    metamacro_at(20, __VA_ARGS__, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxTuple, RxFiveTuple, RxFourTuple, RxThreeTuple, RxTwoTuple, RxOneTuple)

#define RxTupleUnpack_(...) \
    metamacro_foreach(RxTupleUnpack_decl,, __VA_ARGS__) \
    \
    int RxTupleUnpack_state = 0; \
    \
    RxTupleUnpack_after: \
        ; \
        metamacro_foreach(RxTupleUnpack_assign,, __VA_ARGS__) \
        if (RxTupleUnpack_state != 0) RxTupleUnpack_state = 2; \
        \
            while (RxTupleUnpack_state != 2) \
                if (RxTupleUnpack_state == 1) { \
                    goto RxTupleUnpack_after; \
                } else \
                    for (; RxTupleUnpack_state != 1; RxTupleUnpack_state = 1) \
                        [RxTupleUnpackingTrampoline trampoline][@[metamacro_foreach(RxTupleUnpack_value,, __VA_ARGS__)]]

#define RxTupleUnpack_state metamacro_concat(RxTupleUnpack_state, __LINE__)
#define RxTupleUnpack_after metamacro_concat(RxTupleUnpack_after, __LINE__)
#define RxTupleUnpack_loop metamacro_concat(RxTupleUnpack_loop, __LINE__)

#define RxTupleUnpack_decl_name(INDEX) \
    metamacro_concat(metamacro_concat(RxTupleUnpack, __LINE__), metamacro_concat(_var, INDEX))

#define RxTupleUnpack_decl(INDEX, ARG) \
    __strong id RxTupleUnpack_decl_name(INDEX);

#define RxTupleUnpack_assign(INDEX, ARG) \
    __strong ARG = RxTupleUnpack_decl_name(INDEX);

#define RxTupleUnpack_value(INDEX, ARG) \
    [NSValue valueWithPointer:&RxTupleUnpack_decl_name(INDEX)],

@interface RxTupleUnpackingTrampoline : NSObject

+ (instancetype)trampoline;

- (void)setObject:(RxTuple *)tuple forKeyedSubscript:(NSArray *)variables;

@end

NS_ASSUME_NONNULL_END
