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

//! Project version number for RxCoreComponents.
FOUNDATION_EXPORT double RxCoreComponentsVersionNumber;

//! Project version string for RxCoreComponents.
FOUNDATION_EXPORT const unsigned char RxCoreComponentsVersionString[];

#import <RxCoreComponents/metamacros.h>

#if __has_include(<RxCoreComponents/RxPair.h>)
#import <RxCoreComponents/RxPair.h>
#endif

#if __has_include(<RxCoreComponents/RxLock.h>)
#import <RxCoreComponents/RxLock.h>
#endif

#if __has_include(<RxCoreComponents/RxCancellable.h>)
#import <RxCoreComponents/RxCancellable.h>
#endif

#if __has_include(<RxCoreComponents/RxComparable.h>)
#import <RxCoreComponents/RxComparable.h>
#endif

#if __has_include(<RxCoreComponents/RxDynamicCast.h>)
#import <RxCoreComponents/RxDynamicCast.h>
#endif

#if __has_include(<RxCoreComponents/RxJSONMapping.h>)
#import <RxCoreComponents/RxJSONMapping.h>
#import <RxCoreComponents/RxSharedObjectsCache.h>
#endif

#if __has_include(<RxCoreComponents/RxJSONSerialization.h>)
#import <RxCoreComponents/RxJSONSerialization.h>
#endif

#if __has_include(<RxCoreComponents/RxPrimaryKey.h>)
#import <RxCoreComponents/RxPrimaryKey.h>
#endif

#if __has_include(<RxCoreComponents/RxWeakProxy.h>)
#import <RxCoreComponents/RxWeakProxy.h>
#endif

#if __has_include(<RxCoreComponents/JRSwizzle.h>)
#import <RxCoreComponents/JRSwizzle.h>
#endif

#if __has_include(<RxCoreComponents/NSObject+RxDynamicCast.h>)
#import <RxCoreComponents/NSObject+RxDynamicCast.h>
#endif

#if __has_include(<RxCoreComponents/NSObject+RxDelayedPerforming.h>)
#import <RxCoreComponents/NSObject+RxDelayedPerforming.h>
#endif

#if __has_include(<RxCoreComponents/NSObject+Deallocating.h>)
#import <RxCoreComponents/NSObject+Deallocating.h>
#endif

#if __has_include(<RxCoreComponents/RxMultipleDelegate.h>)
#import <RxCoreComponents/RxMultipleDelegate.h>
#endif

#if __has_include(<RxCoreComponents/RxObjectEquality.h>)
#import <RxCoreComponents/RxObjectEquality.h>
#endif

#if __has_include(<RxCoreComponents/RxTuple.h>)
#import <RxCoreComponents/RxTuple.h>
#endif

#if __has_include(<RxCoreComponents/RxVerifyEffective.h>)
#import <RxCoreComponents/RxVerifyEffective.h>
#endif

#if __has_include(<RxCoreComponents/RxActionWhenIdle.h>)
#import <RxCoreComponents/RxActionWhenIdle.h>
#endif
