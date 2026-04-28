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

#import <RxInjector/RxInjectorProtocol.h>

#if TARGET_OS_IPHONE || TARGET_OS_MAC

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface RxInjectorStoryboard :
#if TARGET_OS_IPHONE
UIStoryboard
#elif TARGET_OS_MAC
NSStoryboard
#endif

@property (weak, nonatomic, readonly) id<RxInjector> injector;
+ (instancetype)storyboardWithName:(NSString *)name bundle:(nullable NSBundle *)storyboardBundleOrNil injector:(id<RxInjector>)injector;
@end

NS_ASSUME_NONNULL_END

#endif
