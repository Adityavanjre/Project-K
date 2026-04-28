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

#ifndef DanceUIComposeParagraphIntrinsics_h
#define DanceUIComposeParagraphIntrinsics_h

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

// MARK: - ParagraphIntrinsics Protocol

NS_SWIFT_NAME(ComposeParagraphIntrinsics)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeParagraphIntrinsics  <NSObject>
@property (nonatomic, readonly) CGFloat minIntrinsicWidth;
@property (nonatomic, readonly) CGFloat maxIntrinsicWidth;
@property (nonatomic, readonly) BOOL hasStaleResolvedFonts;
@end

NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeParagraphIntrinsics_h */
