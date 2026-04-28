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

#ifndef DanceUIComposeResourceFactory_h
#define DanceUIComposeResourceFactory_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGColorSpace.h>
#import <QuartzCore/CATransform3D.h>
#import "DanceUIComposeImageBitmap.h"
#import "DanceUIComposePaint.h"
#import "DanceUIComposeRenderNodeLayer.h"
#import "DanceUIComposeParagraph.h"
#import "DanceUIComposeParagraphIntrinsics.h"
#import "DanceUIComposeParagraphStyle.h"
#import "DanceUIComposeSpanStyle.h"
#import "DanceUIComposeTextStyle.h"
#import "DanceUIComposeFont.h"
#import "DanceUIComposeAnnotatedStringRange.h"
#import "DanceUIComposeAsyncImageLoader.h"
#import "DanceUIComposeBreakIterator.h"
#import "DanceUIComposeParagraphPlaceholder.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ComposeResourceFactory)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeResourceFactory <NSObject>

// MARK: Image Decoder

- (id<DanceUIComposeImageBitmap>)makeImageBitmapWithData:(NSData *)data;
- (id<DanceUIComposeImageBitmap>)makeImageBitmapWithFilePath:(NSString *)path;

- (id<DanceUIComposeImageBitmap>)makeVectorImageBitmapWithWidth:(NSInteger)width
                                                           height:(NSInteger)height
                                                           config:(DanceUIComposeImageBitmapConfig)config
                                                         hasAlpha:(BOOL)hasAlpha
                                                       colorSpace:(CGColorSpaceRef)colorSpace;

- (id<DanceUIComposeImageLoadConfig>)makeImageLoadConfig;
- (NSUInteger)makeDisplayListIdentity;

// _notImplemented()
//
//- (id<DanceUIComposeShader>)makeImageShaderWithImage:(UIImage *)image
//                                             tileModeX:(DanceUIComposeTileMode)tileModeX
//                                             tileModeY:(DanceUIComposeTileMode)tileModeY;

// MARK: Gradient

- (id<DanceUIComposeShader>)makeLinearGradientFrom:(CGPoint)from
                                                  to:(CGPoint)to
                                              colors:(NSArray<UIColor *> *)colors
                                          colorStops:(NSArray<NSNumber *> * _Nullable)colorStops
                                            tileMode:(DanceUIComposeTileMode)tileMode;

- (id<DanceUIComposeShader>)makeRadialGradientWithCenter:(CGPoint)center
                                                    radius:(CGFloat)radius
                                                    colors:(NSArray<UIColor *> *)colors
                                                colorStops:(NSArray<NSNumber *> * _Nullable)colorStops
                                                  tileMode:(DanceUIComposeTileMode)tileMode;

- (id<DanceUIComposeShader>)makeSweepGradientWithCenter:(CGPoint)center
                                                   colors:(NSArray<UIColor *> *)colors
                                               colorStops:(NSArray<NSNumber *> * _Nullable)colorStops;


// MARK: Color Filter

- (id<DanceUIComposeColorFilter>)makeTintWithColor:(UIColor *)color blendMode:(CGBlendMode)blendMode;

- (id<DanceUIComposeColorFilter>)makeColorMatrixWithMatrix:(DanceUIComposeColorMatrix)colorMatrix;

- (id<DanceUIComposeColorFilter>)makeLightingWithMultiply:(UIColor *)multiply add:(UIColor *)add;


// MARK: PathEffect

- (id<DanceUIComposePathEffect>)makeDashPathEffectWithIntervals:(NSArray<NSNumber *> *)intervals
                                                            phase:(CGFloat)phase;

// MARK: GraphicsLayerScope
- (id<DanceUIComposeGraphicsLayerScope>)makeComposeGraphicsLayerScope;

// MARK: Paragraph

- (id<DanceUIComposeTextStyle>)makeTextStyleWithSpanStyle:(id<DanceUIComposeSpanStyle>)spanStyle
                                           paragraphStyle:(id<DanceUIComposeParagraphStyle>)paragraphStyle;

- (id<DanceUIComposeSpanStyle>)makeSpanStyleWithTextForegroundColor:(UIColor * _Nullable)textForegroundColor
                                                            textFont:(UIFont * _Nullable)textFont
                                                       letterSpacing:(CGFloat)letterSpacing
                                                        baselineShift:(CGFloat)baselineShift
                                                          localeList:(NSArray<NSString *> * _Nullable)localeList
                                                     backgroundColor:(UIColor * _Nullable)backgroundColor
                                                      textDecoration:(DanceUIComposeTextDecoration)textDecoration
                                                              shadow:(NSShadow * _Nullable)shadow
                                                           drawStyle:(id<DanceUIComposeDrawStyle> _Nullable)drawStyle;

- (id<DanceUIComposeParagraphStyle>)makeParagraphStyleWithTextAlign:(DanceUIComposeTextAlign)textAlign
                                                       textDirection:(DanceUIComposeTextDirection)textDirection
                                                          textIndent:(DanceUIComposeTextIndent)textIndent;

- (id<DanceUIComposeParagraphPlaceholder>)makeParagraphPlaceholderWithWidth:(CGFloat)width height: (CGFloat)height alignment:(int)alignment;

// MARK: - Matrix

- (CATransform3D)makeCATransform3DWithMatrix:(DanceUIRenderNodeLayerMatrix)matrix;

// MARK: - Draw Style

- (id<DanceUIComposeFill>)makeFillDrawStyle;
- (id<DanceUIComposeStroke>)makeStrokeDrawStyleWithWidth:(CGFloat)width
                                                   miter:(CGFloat)miter
                                                     cap:(DanceUIComposeStrokeCap)cap
                                                    join:(DanceUIComposeStrokeJoin)join
                                              pathEffect:(id<DanceUIComposePathEffect> _Nullable)pathEffect;

// MARK: - AnnotatedString Range

- (id<DanceUIComposeAnnotatedStringRangeWithSpanStyle>)makeAnnotatedStringRangeWithSpanStyleWithRange:(NSRange)range
                                                                                            spanStyle:(id<DanceUIComposeSpanStyle>)spanStyle;

- (id<DanceUIComposeAnnotatedStringRangeWithPlaceholder>)makeAnnotatedStringRangeWithPlaceHolderWithRange:(NSRange)range
                                                                                              placeHolder:(id<DanceUIComposeParagraphPlaceholder>)placeHolder;


- (id<DanceUIComposeBreakIterator>)makeBreakIteratorCharacterInstance;

@end

NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeResourceFactory_h */
