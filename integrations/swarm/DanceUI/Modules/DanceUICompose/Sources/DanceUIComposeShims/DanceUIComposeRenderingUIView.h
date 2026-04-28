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

#ifndef RenderingUIView_h
#define RenderingUIView_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DanceUIComposeCanvas.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DanceUIComposeTouchesEventPhase) {
    DanceUIComposeTouchesEventPhaseBegan,
    DanceUIComposeTouchesEventPhaseMoved,
    DanceUIComposeTouchesEventPhaseEnded,
    DanceUIComposeTouchesEventPhaseCancelled
} NS_SWIFT_NAME(ComposeTouchesEventPhase);

NS_SWIFT_NAME(ComposeRenderingUIView)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeRenderingUIView <NSObject>

@property (nonatomic, readwrite, assign) bool isNeedHighFrequencyPolling;
@property (nonatomic, readwrite, assign) bool isApplicationActive;
@property (nonatomic, readwrite, copy) void (^_Nullable onAttachedToWindowBlock)(void) NS_SWIFT_NAME(onAttachedToWindow);
@property (nonatomic, readwrite, assign) bool isPresentWithTransactionEveryFrame;
@property (nonatomic, readwrite, assign) bool disableRendering;

- (void)onTouchesEventWithID:(NSInteger)identity
                    position:(CGPoint)position
                       phase:(DanceUIComposeTouchesEventPhase)phase NS_SWIFT_NAME(onTouchesEvent(_:position:phase:));

- (void)onTouchesCancelled;

- (void)needRedraw;

- (void)dispose;

- (long)leftTimeNanos;

- (void)renderImmediately;

@end

NS_SWIFT_NAME(ComposeRenderDelegate)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeRenderDelegate <NSObject>

- (void)onRenderWithCanvas:(id<DanceUIComposeCanvas>)canvas
                     width:(CGFloat)width
                    height:(CGFloat)height
                  nanoTime:(CGFloat)nanoTime;

- (void)retrieveInteropTransaction;
- (BOOL)checkUIKitInteropStateBegan;
- (BOOL)checkUIKitInteropStateEnded;
- (void)invokeActionIfNeeded;

@end

NS_ASSUME_NONNULL_END

#endif /* RenderingUIView_h */
