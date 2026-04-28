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

@class RxAnnotationCollection;

NS_ASSUME_NONNULL_BEGIN

/**
  @abstract A named grouping of collections.
 */
@interface RxAnnotationCategory : NSObject <NSCoding>

/**
 @abstract The name of the category.
 */
@property (copy, nonatomic, readonly) NSString *name;

/**
 @abstract The collections contained in this category.
 */
@property (copy, nonatomic, readonly) NSArray<RxAnnotationCollection *> *annotationCollections;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

/**
  @abstract Creates a annotation category.
  @discussion This is the designated initializer.
 */
- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;


/**
  @abstract Fetches a collection by name.
  @param name The collection name to find.
 */
- (RxAnnotationCollection *)annotationCollectionWithName:(NSString *)name;

/**
 @abstract Adds a annotation collection to the category.
 @param annotationCollection The annotation collection to add.
 */
- (void)addAnnotationCollection:(RxAnnotationCollection *)annotationCollection;

/**
 @abstract Removes a annotation collection from the category.
 @param annotationCollection The annotation collection to remove.
 */
- (void)removeAnnotationCollection:(RxAnnotationCollection *)annotationCollection;

@end

NS_ASSUME_NONNULL_END
