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

#ifndef DanceUIComposePaint_h
#define DanceUIComposePaint_h

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "DanceUIComposeDrawStyle.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0)) @protocol DanceUIComposePathEffect;

// MARK: PaintingStyle

typedef NS_ENUM(NSInteger, DanceUIComposePaintingStyle) {
    DanceUIComposePaintingStyleFill,
    DanceUIComposePaintingStyleStroke
} NS_SWIFT_NAME(ComposePaintingStyle);

// MARK: FilterQuality

typedef NS_ENUM(NSInteger, DanceUIComposeFilterQuality) {
    DanceUIComposeFilterQualityNone,
    DanceUIComposeFilterQualityLow,
    DanceUIComposeFilterQualityMedium,
    DanceUIComposeFilterQualityHigh
} NS_SWIFT_NAME(ComposeFilterQuality);

// MARK: Shader

typedef NS_ENUM(NSInteger, DanceUIComposeTileMode) {
    DanceUIComposeTileModeClamp,
    DanceUIComposeTileModeRepeat,
    DanceUIComposeTileModeMirror
} NS_SWIFT_NAME(ComposeTileMode);

typedef NS_ENUM(NSInteger, DanceUIComposeShaderMode) {
    DanceUIComposeShaderModeGradient,
    DanceUIComposeShaderModeImage,
} NS_SWIFT_NAME(ComposeShaderMode);

NS_SWIFT_NAME(ComposeShader)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeShader <NSObject>

@property (class, nonatomic, readonly, assign) DanceUIComposeShaderMode mode;

@end

// MARK: ColorFilter

API_AVAILABLE(ios(13.0)) typedef struct {
    float m11, m12, m13, m14, m15;
    float m21, m22, m23, m24, m25;
    float m31, m32, m33, m34, m35;
    float m41, m42, m43, m44, m45;
} DanceUIComposeColorMatrix NS_SWIFT_NAME(ComposeColorMatrix);

API_AVAILABLE(ios(13.0))
static inline DanceUIComposeColorMatrix DanceUIComposeColorMatrixMake(
    CGFloat m11, CGFloat m12, CGFloat m13, CGFloat m14, CGFloat m15,
    CGFloat m21, CGFloat m22, CGFloat m23, CGFloat m24, CGFloat m25,
    CGFloat m31, CGFloat m32, CGFloat m33, CGFloat m34, CGFloat m35,
    CGFloat m41, CGFloat m42, CGFloat m43, CGFloat m44, CGFloat m45)
{
    DanceUIComposeColorMatrix matrix;
    matrix.m11 = m11; matrix.m12 = m12; matrix.m13 = m13; matrix.m14 = m14; matrix.m15 = m15;
    matrix.m21 = m21; matrix.m22 = m22; matrix.m23 = m23; matrix.m24 = m24; matrix.m25 = m25;
    matrix.m31 = m31; matrix.m32 = m32; matrix.m33 = m33; matrix.m34 = m34; matrix.m35 = m35;
    matrix.m41 = m41; matrix.m42 = m42; matrix.m43 = m43; matrix.m44 = m44; matrix.m45 = m45;
    return matrix;
}

typedef NS_ENUM(NSInteger, DanceUIComposeColorFilterType) {
    DanceUIComposeColorFilterTintColor,
    DanceUIComposeColorFilterColorMatrix,
    DanceUIComposeColorFilterLighting,
} NS_SWIFT_NAME(ComposeColorFilterType);

NS_SWIFT_NAME(ComposeColorFilter)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeColorFilter <NSObject>

@property (nonatomic, readonly) DanceUIComposeColorFilterType type;

@end

// MARK: Paint

/// Paint protocol defines the properties and methods for controlling how shapes and images are drawn
NS_SWIFT_NAME(ComposePaint)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposePaint <NSObject>

@property (nonatomic, assign) CGFloat alpha;

@property (nonatomic, assign) BOOL isAntiAlias;

@property (nonatomic, strong) UIColor *color;

@property (nonatomic, assign) CGBlendMode blendMode;

@property (nonatomic, assign) DanceUIComposePaintingStyle style;

@property (nonatomic, assign) CGFloat strokeWidth;

@property (nonatomic, assign) DanceUIComposeStrokeCap strokeCap;

@property (nonatomic, assign) DanceUIComposeStrokeJoin strokeJoin;

@property (nonatomic, assign) CGFloat strokeMiterLimit;

@property (nonatomic, assign) DanceUIComposeFilterQuality filterQuality;

@property (nonatomic, strong, nullable) id<DanceUIComposeShader> shader;

@property (nonatomic, strong, nullable) id<DanceUIComposeColorFilter> colorFilter;

@property (nonatomic, strong, nullable) id<DanceUIComposePathEffect> pathEffect;

@end


NS_ASSUME_NONNULL_END

#endif /* DanceUIComposePaint_h */
