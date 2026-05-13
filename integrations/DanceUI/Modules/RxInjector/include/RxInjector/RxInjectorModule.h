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

@protocol RxInjector, RxInjectorBinder;

NS_ASSUME_NONNULL_BEGIN

@protocol RxInjectorModule <NSObject>
@required
- (void)bindModule:(id<RxInjectorBinder>)binder;
@end

@interface RxInjectorModule : NSObject

/**
 * Returns a RxInjector configured with the module.
 */
+ (id<RxInjector>)bindModule:(id<RxInjectorModule>)module;

/**
 * Returns a RxInjector configured with the modules. Starting at index 0, each module
 * will in turn have it configure: method called. Thus, if two modules bind to the same
 * key, the second binding will win.
 */
+ (id<RxInjector>)bindModules:(NSArray<id<RxInjectorModule>> *)modules;

@end

NS_ASSUME_NONNULL_END
