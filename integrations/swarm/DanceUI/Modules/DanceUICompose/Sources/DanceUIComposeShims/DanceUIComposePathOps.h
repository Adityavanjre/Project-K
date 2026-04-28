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

#ifndef DanceUIComposePathOps_h
#define DanceUIComposePathOps_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ComposePathOps)
API_AVAILABLE(ios(13.0))
@protocol DanceUIComposePathOps <NSObject>

- (CGPathRef)unionPath:(CGPathRef)sourcePath
              maskPath:(CGPathRef)maskPath
               evenOdd:(BOOL)evenOdd CF_RETURNS_NOT_RETAINED;

- (CGPathRef)intersectPath:(CGPathRef)sourcePath
                  maskPath:(CGPathRef)maskPath
                   evenOdd:(BOOL)evenOdd CF_RETURNS_NOT_RETAINED;

- (CGPathRef)subtractPath:(CGPathRef)sourcePath
                 maskPath:(CGPathRef)maskPath
                  evenOdd:(BOOL)evenOdd CF_RETURNS_NOT_RETAINED;

- (CGPathRef)xorPath:(CGPathRef)sourcePath
            maskPath:(CGPathRef)maskPath
             evenOdd:(BOOL)evenOdd CF_RETURNS_NOT_RETAINED;

@end

NS_ASSUME_NONNULL_END

#endif /* DanceUIComposePathOps_h */
