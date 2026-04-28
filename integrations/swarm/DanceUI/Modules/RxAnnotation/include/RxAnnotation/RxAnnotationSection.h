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

@class RxAnnotationCategory;

NS_ASSUME_NONNULL_BEGIN

@interface RxAnnotationSection : NSObject <NSCoding>

@property (copy, nonatomic, readonly) NSString *name;
@property (copy, nonatomic, readonly) NSArray<RxAnnotationCategory *> *annotationCategories;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

/**
 @abstract Creates a annotation section.
 @discussion This is the designated initializer.
 */
- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;

- (nullable RxAnnotationCategory *)annotationCategoryWithName:(NSString *)name;

/**
 @abstract Adds a annotation category to the category.
 @param annotationCategory The annotation category to add.
 */
- (void)addAnnotationCategory:(RxAnnotationCategory *)annotationCategory;

/**
 @abstract Removes a annotation category from the category.
 @param annotationCategory The annotation category to remove.
 */
- (void)removeAnnotationCategory:(RxAnnotationCategory *)annotationCategory;

@end

NS_ASSUME_NONNULL_END
