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

#ifndef DanceUIComposeSpanStyle_h
#define DanceUIComposeSpanStyle_h

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeDrawStyle;

/**
 * Defines horizontal lines to be drawn on text.
 * Can be used in Swift as an OptionSet.
 */
typedef NS_OPTIONS(NSUInteger, DanceUIComposeTextDecoration) {
    DanceUIComposeTextDecorationNone = 0,
    DanceUIComposeTextDecorationUnderline = 1 << 0,  // 0x1
    DanceUIComposeTextDecorationLineThrough = 1 << 1,  // 0x2
} NS_SWIFT_NAME(ComposeTextDecoration);

// MARK: - Compose SpanStyle Protocol

/**
 * Styling configuration for a text span. This configuration only allows character level styling,
 * in order to set paragraph level styling such as line height, or text alignment please see
 * [ParagraphStyle].
 */
NS_SWIFT_NAME(ComposeSpanStyle)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeSpanStyle <NSObject>

@property (nonatomic, strong, nullable, readonly) UIColor *textForegroundColor;
@property (nonatomic, strong, nullable, readonly) UIFont *textFont;
@property (nonatomic, assign, readonly) CGFloat letterSpacing;
@property (nonatomic, assign, readonly) CGFloat baselineShift;
@property (nonatomic, strong, nullable, readonly) NSArray<NSString *> *localeList;
@property (nonatomic, strong, nullable, readonly) UIColor *backgroundColor;
@property (nonatomic, assign, readonly) DanceUIComposeTextDecoration textDecoration;
@property (nonatomic, strong, nullable, readonly) NSShadow *shadow;
@property (nonatomic, strong, nullable, readonly) id<DanceUIComposeDrawStyle> drawStyle;

@end

NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeSpanStyle_h */
