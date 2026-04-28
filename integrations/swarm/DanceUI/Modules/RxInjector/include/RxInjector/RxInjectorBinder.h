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

@protocol RxInjectorProvider, RxInjectorScope;

NS_ASSUME_NONNULL_BEGIN

typedef __nonnull id(^RxInjectorBlock)(NSArray *args, id<RxInjector> injector);

@protocol RxInjectorBinder <NSObject>

/**
 * Binds the key to the instance. Requests for an instance given the key, whether made
 * directly to the injector or made internally by the injector, will always return this
 * instance.
 */
- (void)bind:(id)key toInstance:(id)instance;

/**
 * Binds the key to the provider. Requests for an instance given the key will forward
 * the request to the provider. The object returned by the provider will be the object
 * returned to the original request.
 *
 * If any arguments are passed to [injector getInstance:], these arguments will be passed
 * to the provider.
 */
- (void)bind:(id)key toProvider:(id<RxInjectorProvider>)provider;

/**
 * Binds the key to a block. Requests for an instance given the key will execute the block
 * and return the block's return value.
 *
 * If any arguments are passed to [injector getInstance:], these arguments will be passed
 * to the block.
 *
 * This trivial example shows how block binding with dynamic args works:
 *
 * \code
 * @implementation MyModule
 *
 * - (void)bindModule:(id<RxInjectorBinder>)binder {
 *   __block NSString *lastName = @"Thompson";
 *
 *   [binder bind:@"fullName" toBlock:^id()(NSArray *args, id<RxInjector> injector){
 *        NSString *firstName = args[0];
 *        return [NSString stringWithFormat:@"%@ %@", firstName, lastName, nil];
 *   }];
 * }
 *
 *  ... elsewhere:
 *
 *  NSString *fullName = [injector getInstance:@"fullName" withArgs:@"Jenny", nil];
 *  // Jenny Thompson
 * \endcode
 *
 */
- (void)bind:(id)key toBlock:(RxInjectorBlock)block;

/**
 * Binds the key to the class. A request for an instance given the key will return an
 * an instance of the class. How this happens will depend on other configurations.
 *
 * For example, imagine a call to [injector getInstance:[Foo class]];
 *
 * If no bindings have been created using [Foo class] as a key, then RxInjector will try to
 * create a Foo instance using the Foo class' rxInjectorInitializer.
 *
 * If [Foo class] had been bound to a block, then the block would be invoked and its
 * return value would be passed to the caller of getInstance:
 *
 * If [Foo class] had been bound to a RxInjectorProvider, then the provider's provide: method
 * would be called and the return value would be passed to the caller of getInstance:
 */
- (void)bind:(id)key toClass:(Class)type;

/**
 * Same as above, with the additional introduction of scoping. Within a
 * call to [injector getInstance:[Foo class]], the scope will decide whether
 * a new Foo should be created, or whether an existing instance should be returned.
 */
- (void)bind:(id)key toClass:(Class)type withScope:(id<RxInjectorScope>)scope;

/**
 * Defines the scope to be used with the key. The scoping applies to existing bindings
 * for the key, and will apply to future bindings as well. To remove a scope, call
 *
 * [binder bind:key withScope:nil];
 *
 */
- (void)bind:(id)key withScope:(id<RxInjectorScope>)scope;

@end

NS_ASSUME_NONNULL_END
