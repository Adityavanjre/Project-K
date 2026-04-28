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

#ifndef DanceUIComposeParagraphStyle_h
#define DanceUIComposeParagraphStyle_h

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0)) typedef NS_CLOSED_ENUM(uint32_t, DanceUIComposeTextAlign) {
    DanceUIComposeTextAlignUnspecified = 0,
    DanceUIComposeTextAlignLeft = 1,
    DanceUIComposeTextAlignRight = 2,
    DanceUIComposeTextAlignCenter = 3,
    DanceUIComposeTextAlignJustified = 4,
    DanceUIComposeTextAlignLeading = 5,
    DanceUIComposeTextAlignTrailing = 6,
} NS_SWIFT_NAME(ComposeTextAlign);

API_AVAILABLE(ios(13.0)) typedef NS_CLOSED_ENUM(uint32_t, DanceUIComposeTextDirection) {
    DanceUIComposeTextDirectionUnspecified = 0,
    DanceUIComposeTextDirectionLeftToRight = 1,
    DanceUIComposeTextDirectionRightToLeft = 2,
} NS_SWIFT_NAME(ComposeTextDirection);

NS_SWIFT_NAME(ComposeTextIndent)
API_AVAILABLE(ios(13.0)) typedef struct DanceUIComposeTextIndent {
    CGFloat firstLine;
    CGFloat restLine;
} NS_SWIFT_NAME(ComposeTextIndent) DanceUIComposeTextIndent NS_SWIFT_NAME(ComposeTextIndent);

// MARK: - Compose ParagraphStyle Protocol

NS_SWIFT_NAME(ComposeParagraphStyle)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeParagraphStyle <NSObject>

@property (nonatomic, readonly) DanceUIComposeTextAlign textAlign;
@property (nonatomic, readonly) DanceUIComposeTextDirection textDirection;
@property (nonatomic, readonly) DanceUIComposeTextIndent textIndent;

@end

NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeParagraphStyle_h */
