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

#ifndef DanceUIComposeParagraph_h
#define DanceUIComposeParagraph_h

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "DanceUIComposeParagraphStyle.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeCanvas;
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeParagraphIntrinsics;

// MARK: - Paragraph Protocol

NS_SWIFT_NAME(ComposeTextRange)
API_AVAILABLE(ios(13.0)) typedef struct DanceUIComposeTextRange {
    NSInteger start;
    NSInteger end;
} NS_SWIFT_NAME(ComposeTextRange) DanceUIComposeTextRange NS_SWIFT_NAME(ComposeTextRange);


NS_SWIFT_NAME(ComposeParagraph)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeParagraph <NSObject>

// MARK: - Properties

@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) CGFloat minIntrinsicWidth;
@property (nonatomic, readonly) CGFloat maxIntrinsicWidth;
@property (nonatomic, readonly) CGFloat firstBaseline;
@property (nonatomic, readonly) CGFloat lastBaseline;
@property (nonatomic, readonly) NSArray<NSValue *> * placeholderRects;

- (instancetype)initWithIntrinsics:(id<DanceUIComposeParagraphIntrinsics>)intrinsics minWidth:(NSInteger)minWidth maxWidth:(NSInteger)maxWidth minHeight:(NSInteger)minHeight maxHeight:(NSInteger)maxHeight maxLines:(NSInteger)maxLines ellipsis:(BOOL)ellipsis;

// MARK: - Rendering

- (void)paintWithCanvas:(id<DanceUIComposeCanvas>)canvas paint:(id<DanceUIComposePaint> _Nullable)paint color:(UIColor *)color shadow:(nullable NSShadow *)shadow;

// MARK: - Cursor and Position APIs

/// Returns the cursor rectangle at the given character offset
/// @param offset Character offset (0-based, can be 0 to text.length inclusive)
/// @return Rectangle with zero width from line top to bottom
- (CGRect)getCursorRectWithOffset:(NSInteger)offset;

/// Returns the character offset at the given screen position
/// @param position Touch/click position in pixels
/// @return Character offset closest to the position
- (NSInteger)getOffsetForPosition:(CGPoint)position;

/// Returns the horizontal X position for the cursor at the given offset
/// @param offset Character offset
/// @param usePrimaryDirection Whether to use primary text direction
/// @return X coordinate in pixels
- (CGFloat)getHorizontalPositionWithOffset:(NSInteger)offset usePrimaryDirection:(BOOL)usePrimaryDirection;

/// Returns the bounding box for the character at the given offset
/// @param offset Character offset
/// @return Rectangle enclosing the character
- (CGRect)getBoundingBoxWithOffset:(NSInteger)offset;

/// Returns an array of rectangles covering the text range for selection highlighting
/// @param start Start character offset (inclusive)
/// @param end End character offset (exclusive)
/// @return Array of CGRect values (as NSValue) covering the range
- (NSArray<NSValue *> *)getRectsForRangeWithStart:(NSInteger)start end:(NSInteger)end;

// MARK: - Line APIs

/// Returns the line index containing the given character offset
/// @param offset Character offset
/// @return Zero-based line index
- (NSInteger)getLineForOffset:(NSInteger)offset;

/// Returns the line index at the given Y coordinate
/// @param vertical Y coordinate in pixels
/// @return Zero-based line index
- (NSInteger)getLineForVerticalPosition:(CGFloat)vertical;

/// Returns the Y coordinate of the top of the specified line
/// @param lineIndex Zero-based line index
/// @return Y coordinate in pixels
- (CGFloat)getLineTopWithLineIndex:(NSInteger)lineIndex;

/// Returns the Y coordinate of the bottom of the specified line
/// @param lineIndex Zero-based line index
/// @return Y coordinate in pixels
- (CGFloat)getLineBottomWithLineIndex:(NSInteger)lineIndex;

/// Returns the height of the specified line
/// @param lineIndex Zero-based line index
/// @return Height in pixels
- (CGFloat)getLineHeightWithLineIndex:(NSInteger)lineIndex;

/// Returns the left edge X coordinate of the line's content
/// @param lineIndex Zero-based line index
/// @return X coordinate in pixels
- (CGFloat)getLineLeftWithLineIndex:(NSInteger)lineIndex;

/// Returns the right edge X coordinate of the line's content
/// @param lineIndex Zero-based line index
/// @return X coordinate in pixels
- (CGFloat)getLineRightWithLineIndex:(NSInteger)lineIndex;

/// Returns the width of the line's content
/// @param lineIndex Zero-based line index
/// @return Width in pixels
- (CGFloat)getLineWidthWithLineIndex:(NSInteger)lineIndex;

/// Returns the character offset of the first character in the line
/// @param lineIndex Zero-based line index
/// @return Character offset
- (NSInteger)getLineStartWithLineIndex:(NSInteger)lineIndex;

/// Returns the character offset of the last character in the line
/// @param lineIndex Zero-based line index
/// @param visibleEnd If true, excludes trailing whitespace
/// @return Character offset
- (NSInteger)getLineEndWithLineIndex:(NSInteger)lineIndex visibleEnd:(BOOL)visibleEnd;

/// Checks if the line is truncated with ellipsis
/// @param lineIndex Zero-based line index
/// @return True if the line is truncated
- (BOOL)isLineEllipsizedWithLineIndex:(NSInteger)lineIndex;

// MARK: - Word Boundary

/// Returns the word boundary containing the given offset
/// @param offset Character offset
/// @return Text range with start and end of the word
- (DanceUIComposeTextRange)getWordBoundaryWithOffset:(NSInteger)offset NS_SWIFT_NAME(wordBoundary(with:));

// MARK: - Text Direction (BiDi Support)

/// Returns the paragraph-level text direction
/// @param offset Character offset
/// @return Text direction
- (DanceUIComposeTextDirection)getParagraphDirectionWithOffset:(NSInteger)offset NS_SWIFT_NAME(paragraphDirection(with:));

/// Returns the BiDi run direction at the given offset
/// @param offset Character offset
/// @return Text direction of the BiDi run
- (DanceUIComposeTextDirection)getBidiRunDirectionWithOffset:(NSInteger)offset NS_SWIFT_NAME(bidiRunDirection(with:));

@end

NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeParagraph_h */
