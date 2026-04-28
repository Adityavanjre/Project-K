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
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "DanceUIComposePaint.h"
#import "DanceUIComposeImageBitmap.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0)) @protocol DanceUIComposePaint;
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeImageBitmap;
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeAnyResolvedPaint;
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeStrokeStyle;
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposePath;
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeFillStyle;

// MARK: - Enums

typedef NS_ENUM(NSInteger, DanceUIComposeClipOp) {
    DanceUIComposeClipOpIntersect,
    DanceUIComposeClipOpDifference
} NS_SWIFT_NAME(ComposeClipOp);

typedef NS_ENUM(NSInteger, DanceUIComposeGraphicsBlendMode) {
    DanceUIComposeGraphicsBlendModeDefault
    // Add other blend modes as needed
} NS_SWIFT_NAME(ComposeGraphicsBlendMode);

// MARK: - Canvas Protocol

API_AVAILABLE(ios(13.0))
NS_SWIFT_NAME(ComposeCanvas)
@protocol DanceUIComposeCanvas <NSObject>

- (void)save;
- (void)restore;

// TODO: Unimplemented yet
- (void)saveLayerWithBounds:(CGRect)bounds paint:(id<DanceUIComposePaint>)paint;

/// Translate on the current canvas context
- (void)translateWithDx:(CGFloat)dx dy:(CGFloat)dy NS_SWIFT_NAME(translate(dx:dy:));

- (void)resizeLayerWithSize:(CGSize)size NS_SWIFT_NAME(resizeLayer(size:));
- (void)scaleWithSx:(CGFloat)sx sy:(CGFloat)sy NS_SWIFT_NAME(scale(sx:sy:));
- (void)rotateWithDegrees:(CGFloat)degrees NS_SWIFT_NAME(rotate(degrees:));
- (void)concatWithMatrix:(CATransform3D)matrix NS_SWIFT_NAME(concat(matrix:));
- (void)setOpacity:(CGFloat)opacity;

// Default implementations in Swift extension
- (void)scaleWithSx:(CGFloat)sx NS_SWIFT_NAME(scale(sx:));
- (void)scaleWithSx:(CGFloat)sx sy:(CGFloat)sy pivotX:(CGFloat)pivotX pivotY:(CGFloat)pivotY NS_SWIFT_NAME(scale(sx:sy:pivotX:pivotY:));
- (void)rotateWithDegrees:(CGFloat)degrees pivotX:(CGFloat)pivotX pivotY:(CGFloat)pivotY NS_SWIFT_NAME(rotate(degrees:pivotX:pivotY:));
- (void)rotateRadWithRadians:(CGFloat)radians pivotX:(CGFloat)pivotX pivotY:(CGFloat)pivotY NS_SWIFT_NAME(rotate(radians:pivotX:pivotY:));

// TODO: Path & Paint
- (void)clipRectWithRect:(CGRect)rect clipOp:(DanceUIComposeClipOp)clipOp;
- (void)clipRectWithLeft:(CGFloat)left top:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom clipOp:(DanceUIComposeClipOp)clipOp;
- (void)clipRoundRectWithRect:(CGRect)rect radiusX:(CGFloat)radiusX radiusY:(CGFloat)radiusY clipOp:(DanceUIComposeClipOp)clipOp;
- (void)clipPathWithPath:(CGPathRef)path clipOp:(DanceUIComposeClipOp)clipOp;
- (void)drawLineWithP1:(CGPoint)p1 p2:(CGPoint)p2 paint:(id<DanceUIComposePaint>)paint;
- (void)drawRectWithRect:(CGRect)rect paint:(id<DanceUIComposePaint>)paint;
- (void)drawRectWithLeft:(CGFloat)left top:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom paint:(id<DanceUIComposePaint>)paint;
- (void)drawRoundRectWithLeft:(CGFloat)left top:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom radiusX:(CGFloat)radiusX radiusY:(CGFloat)radiusY paint:(id<DanceUIComposePaint>)paint;
- (void)drawOvalWithRect:(CGRect)rect paint:(id<DanceUIComposePaint>)paint;
- (void)drawOvalWithLeft:(CGFloat)left top:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom paint:(id<DanceUIComposePaint>)paint;
- (void)drawCircleWithCenter:(CGPoint)center radius:(CGFloat)radius paint:(id<DanceUIComposePaint>)paint;
- (void)drawArcWithRect:(CGRect)rect startAngle:(CGFloat)startAngle sweepAngle:(CGFloat)sweepAngle useCenter:(BOOL)useCenter paint:(id<DanceUIComposePaint>)paint;
- (void)drawArcWithLeft:(CGFloat)left top:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom startAngle:(CGFloat)startAngle sweepAngle:(CGFloat)sweepAngle useCenter:(BOOL)useCenter paint:(id<DanceUIComposePaint>)paint;
- (void)drawPathWithPath:(CGPathRef)path paint:(id<DanceUIComposePaint>)paint;
- (void)drawImageWithImage:(id<DanceUIComposeImageBitmap>)image topLeftOffset:(CGPoint)topLeftOffset paint:(id<DanceUIComposePaint>)paint NS_SWIFT_NAME(drawImage(with:topLeftOffset:paint:));
- (void)drawImageRectWithImage:(id<DanceUIComposeImageBitmap>)image srcOffset:(CGPoint)srcOffset srcSize:(CGSize)srcSize dstOffset:(CGPoint)dstOffset dstSize:(CGSize)dstSize paint:(id<DanceUIComposePaint>)paint NS_SWIFT_NAME(drawImageRect(with:srcOffset:srcSize:dstOffset:dstSize:paint:));

- (void)drawPlatformView:(UIView *)view
                       x:(CGFloat)x
                       y:(CGFloat)y
                   width:(CGFloat)width
                  height:(CGFloat)height
                identity:(NSUInteger)identity NS_SWIFT_NAME(drawPlatformView(_:x:y:width:height:identity:));

@end

// MARK: - Supporting Types

// Path Protocol
NS_SWIFT_NAME(ComposePath)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposePath <NSObject>
// Path define
@end

NS_ASSUME_NONNULL_END
