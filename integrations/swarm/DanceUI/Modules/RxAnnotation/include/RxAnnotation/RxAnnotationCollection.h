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

@class RxAnnotation;

NS_ASSUME_NONNULL_BEGIN

/**
  @abstract A named collection of annotations.
 */
@interface RxAnnotationCollection : NSObject <NSCoding>

/**
 @abstract The name of the collection.
 */
@property (copy, nonatomic, readonly) NSString *name;

/**
 @abstract The annotations contained in this collection.
 */
@property (copy, nonatomic, readonly) NSArray<RxAnnotation *> *annotations;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

/**
  @abstract Creates a annotation collection.
  @discussion This is the designated initializer.
 */
- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;

/**
  @abstract Fetches a annotation by identifier.
  @param identifier The annotation identifier to find.
  @discussion Only search annotations in this collection.
 */
- (RxAnnotation *)annotationWithIdentifier:(NSString *)identifier;

/**
  @abstract Adds a annotation to the collection.
  @param annotation The annotation to add.
 */
- (void)addAnnotation:(RxAnnotation *)annotation;

/**
  @abstract Removes a annotation from the collection.
  @param annotation The annotation to remove.
 */
- (void)removeAnnotation:(RxAnnotation *)annotation;

@end

NS_ASSUME_NONNULL_END
