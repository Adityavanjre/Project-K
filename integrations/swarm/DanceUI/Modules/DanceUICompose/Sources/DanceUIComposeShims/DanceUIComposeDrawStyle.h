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

#ifndef DanceUIComposeDrawStyle_h
#define DanceUIComposeDrawStyle_h

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0)) @protocol DanceUIComposePathEffect;

// MARK: ComposeStrokeCap

typedef NS_ENUM(NSInteger, DanceUIComposeStrokeCap) {
    DanceUIComposeStrokeCapButt,
    DanceUIComposeStrokeCapRound,
    DanceUIComposeStrokeCapSquare
} NS_SWIFT_NAME(ComposeStrokeCap);

// MARK: ComposeStrokeJoin

typedef NS_ENUM(NSInteger, DanceUIComposeStrokeJoin) {
    DanceUIComposeStrokeJoinMiter,
    DanceUIComposeStrokeJoinRound,
    DanceUIComposeStrokeJoinBevel
} NS_SWIFT_NAME(ComposeStrokeJoin);

// MARK: ComposeDrawStyle

NS_SWIFT_NAME(ComposeDrawStyle)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeDrawStyle <NSObject>
@end

// MARK: ComposeFill

NS_SWIFT_NAME(ComposeFill)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeFill <DanceUIComposeDrawStyle>
@end

// MARK: ComposeStroke

NS_SWIFT_NAME(ComposeStroke)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeStroke <DanceUIComposeDrawStyle>

@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat miter;
@property (nonatomic, readonly) DanceUIComposeStrokeCap cap;
@property (nonatomic, readonly) DanceUIComposeStrokeJoin join;
@property (nonatomic, readonly, nullable) id<DanceUIComposePathEffect> pathEffect;
@end

NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeDrawStyle_h */
