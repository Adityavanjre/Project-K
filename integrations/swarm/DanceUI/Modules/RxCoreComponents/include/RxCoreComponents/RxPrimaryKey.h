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

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSExceptionName const RxPrimaryKeyException;

typedef int64_t RxIDType;

@protocol RxPrimaryKey <NSObject>

@required
- (NSString *)getInKey;

@optional
- (RxIDType)numericIDKey;

@end

@interface NSString (PK) <RxPrimaryKey>
@end

@interface NSNumber (PK) <RxPrimaryKey>
@end

@interface RxIntPK : NSObject<RxPrimaryKey>
@property (assign, nonatomic) RxIDType ID;
+ (instancetype)intPKWithID:(RxIDType)ID;
- (instancetype)initWithID:(RxIDType)ID;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (NSUInteger)hash;
- (NSString *)getInKey;
- (BOOL)isEqual:(nullable id)object;
@end

@interface RxStringPK : NSObject<RxPrimaryKey>
@property (strong, nonatomic) NSString *token;
- (instancetype)initWithToken:(NSString *)token;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (NSUInteger)hash;
- (NSString *)getInKey;
- (BOOL)isEqual:(nullable id)object;
@end

@interface NSArray (PrimaryIDs)
- (NSArray<id<RxPrimaryKey>> *)ids;
- (NSArray<NSString *> *)getInKeys;
@end

@protocol RxJSONModel <NSObject>
@optional
- (id)jsonObject;
@end

@interface NSNumber (RSJSONModel) <RxJSONModel>
- (id)jsonObject;
@end

@interface NSString (RSJSONModel) <RxJSONModel>
- (id)jsonObject;
@end

@interface NSArray (RSJSONModel) <RxJSONModel>
- (id)jsonObject;
@end

@interface NSDictionary (RSJSONModel) <RxJSONModel>
- (id)jsonObject;
@end


NS_ASSUME_NONNULL_END
