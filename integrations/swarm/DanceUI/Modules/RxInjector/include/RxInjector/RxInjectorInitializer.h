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

@interface RxInjectorInitializer : NSObject
@property (nonatomic, strong, readonly) Class type;
@property (nonatomic, readonly) SEL selector;
@property (nonatomic, strong, readonly) NSArray *argumentKeys;
+ (instancetype)initializerWithClass:(Class)type selector:(SEL)selector argumentKeys:(nullable id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)initializerWithClass:(Class)type classSelector:(SEL)selector argumentKeys:(nullable id)firstKey, ...
NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)initializerWithClass:(Class)type selector:(SEL)selector argumentKeysArray:(NSArray *)keys;
+ (instancetype)initializerWithClass:(Class)type classSelector:(SEL)selector argumentKeysArray:(NSArray *)keys;

- (instancetype)init NS_UNAVAILABLE;
- (id)rxPerform:(NSArray *)argumentValues;
@end

NS_ASSUME_NONNULL_END
