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

//! Project version number for RxInjector.

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double RxInjectorVersionNumber;

//! Project version string for RxInjector.
FOUNDATION_EXPORT const unsigned char RxInjectorVersionString[];

// Base repos are here:
// https://github.com/jbsf/blindside
// https://github.com/RetVal/blindside  (fixed a thread safe bug)

#import <RxCoreComponents/RxCoreComponents.h>

#import <RxInjector/RxInjectorProtocol.h>
#import <RxInjector/RxInjectorBinder.h>
#import <RxInjector/RxInjectorProvider.h>
#import <RxInjector/RxInjectorNull.h>

#import <RxInjector/RxInjectorScope.h>
#import <RxInjector/RxInjectorSingleton.h>
#import <RxInjector/RxInjectorReusableScope.h>
#import <RxInjector/RxInjectorLazyScope.h>

#import <RxInjector/RxInjectorModule.h>
#import <RxInjector/RxInjectorAppleModule.h>
#import <RxInjector/RxInjectorComponentsModule.h>

#import <RxInjector/NSObject+RxInjector.h>

#if __has_include(<RxInjector/RxInjectorInitializer.h>)

#import <RxInjector/RxInjectorInitializer.h>

#endif

#if __has_include(<RxAnnotation/RxAnnotation.h>)

#import <RxAnnotation/RxAnnotation.h>
#import <RxInjector/RxInjectorAnnotation.h>
#import <RxInjector/RxInjectorAnnotationBasedModule.h>

#endif

#if __has_include(<RxInjector/RxInjectorProperty.h>)

#import <RxInjector/RxInjectorProperty.h>
#import <RxInjector/RxInjectorPropertySet.h>
#import <RxInjector/NSObject+RxInjectorProperties.h>

#endif

#if __has_include(<RxInjector/RxInjectorNib.h>)

#import <RxInjector/RxInjectorNib.h>
#import <RxInjector/RxInjectorStoryboard.h>

#endif
