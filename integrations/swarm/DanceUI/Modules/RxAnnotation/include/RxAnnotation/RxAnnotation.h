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
#import <mach-o/loader.h>

NS_ASSUME_NONNULL_BEGIN

typedef id RxAnnotationValue;

@interface RxAnnotation : NSObject <NSCoding>

@property (copy, nonatomic, readonly) NSString *identifier;
@property (copy, nonatomic, readonly) NSString *name;
@property (copy, nonatomic, readonly) NSString *fileName;
@property (assign, nonatomic, readonly) NSInteger line;
@property (assign, nonatomic, readonly, getter=isAction) BOOL action;

@property (strong, nonatomic, readonly) RxAnnotationValue value;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                             value:(RxAnnotationValue)value
                          fileName:(NSString *)fileName
                              line:(NSInteger)line NS_DESIGNATED_INITIALIZER;

@end

FOUNDATION_EXPORT
NSString *const RxAnnotationInlineLoaderDisabledKey;

FOUNDATION_EXPORT
void RxAnnotationLoaderAddImage(const struct mach_header *mach_header, intptr_t vmaddr_slide);

FOUNDATION_EXPORT
void RxAnnotationLoaderRemoveImage(const struct mach_header *mach_header, intptr_t vmaddr_slide);

NS_ASSUME_NONNULL_END

#import <RxAnnotation/RxAnnotationSection.h>
#import <RxAnnotation/RxAnnotationCategory.h>
#import <RxAnnotation/RxAnnotationCollection.h>
#import <RxAnnotation/RxAnnotationInline.h>
#import <RxAnnotation/RxAnnotationInlineInternal.h>
#import <RxAnnotation/RxAnnotationManager.h>
#import <RxAnnotation/RxAnnotationProcessor.h>
#import <objc/runtime.h>
