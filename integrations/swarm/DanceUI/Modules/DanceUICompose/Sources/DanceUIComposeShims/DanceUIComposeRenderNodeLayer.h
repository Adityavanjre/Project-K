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

#ifndef DanceUIComposeRenderNodeLayer_h
#define DanceUIComposeRenderNodeLayer_h

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "DanceUIComposeCanvas.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ComposeGraphicsLayerScope)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeGraphicsLayerScope <NSObject>

@property (nonatomic, assign) CGFloat alpha;
@property (nonatomic, assign) BOOL alphaChanged;

@property (nonatomic, assign) BOOL tranformChanged;
@property (nonatomic, assign) BOOL clipChanged;

@end

API_AVAILABLE(ios(13.0)) typedef struct {
    CGFloat m11, m12, m13, m14;
    CGFloat m21, m22, m23, m24;
    CGFloat m31, m32, m33, m34;
    CGFloat m41, m42, m43, m44;
} DanceUIRenderNodeLayerMatrix NS_SWIFT_NAME(ComposeRenderNodeLayerMatrix);

API_AVAILABLE(ios(13.0))
static inline DanceUIRenderNodeLayerMatrix DanceUIRenderNodeLayerMatrixMake(
    CGFloat m11, CGFloat m12, CGFloat m13, CGFloat m14,
    CGFloat m21, CGFloat m22, CGFloat m23, CGFloat m24,
    CGFloat m31, CGFloat m32, CGFloat m33, CGFloat m34,
    CGFloat m41, CGFloat m42, CGFloat m43, CGFloat m44)
{
    DanceUIRenderNodeLayerMatrix matrix;
    matrix.m11 = m11; matrix.m12 = m12; matrix.m13 = m13; matrix.m14 = m14;
    matrix.m21 = m21; matrix.m22 = m22; matrix.m23 = m23; matrix.m24 = m24;
    matrix.m31 = m31; matrix.m32 = m32; matrix.m33 = m33; matrix.m34 = m34;
    matrix.m41 = m41; matrix.m42 = m42; matrix.m43 = m43; matrix.m44 = m44;
    return matrix;
}

API_AVAILABLE(ios(13.0))
static const DanceUIRenderNodeLayerMatrix DanceUIRenderNodeLayerMatrixIdentity = {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
};

NS_SWIFT_NAME(ComposeRenderNodeLayer)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeRenderNodeLayer <NSObject>

- (void)destroy;
- (void)reuseLayerWithDrawBlock:(void (^)(id<DanceUIComposeCanvas>))drawBlock
          invalidateParentLayer:(void (^)(void))invalidateParentLayer;
- (void)resize:(CGSize)size;
- (BOOL)moveToX:(CGFloat)x
              y:(CGFloat)y NS_SWIFT_NAME(move(x:y:));
- (void)updateLayerProperties:(id<DanceUIComposeGraphicsLayerScope>)scope;
- (void)invalidate;
- (void)drawLayer:(id<DanceUIComposeCanvas>)canvas
 performDrawBlock:(void (^)(id<DanceUIComposeCanvas>))drawBlock;
- (void)updateDrawTransformWithPivotX:(CGFloat)pivotX
                               pivotY:(CGFloat)pivotY
                            rotationZ:(CGFloat)rotationZ
                            rotationY:(CGFloat)rotationY
                            rotationX:(CGFloat)rotationX
                               scaleX:(CGFloat)scaleX
                               scaleY:(CGFloat)scaleY
                         translationX:(CGFloat)translationX
                         translationY:(CGFloat)translationY
                       cameraDistance:(CGFloat)cameraDistance NS_SWIFT_NAME(updateDrawTransform(pivotX:pivotY:rotationZ:rotationY:rotationX:scaleX:scaleY:translationX:translationY:cameraDistance:));

@end

NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeRenderNodeLayer_h */
