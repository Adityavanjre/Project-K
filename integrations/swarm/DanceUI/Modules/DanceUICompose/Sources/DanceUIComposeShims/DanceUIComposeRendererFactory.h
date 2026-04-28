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

#ifndef DanceUIComposeRendererFactory_h
#define DanceUIComposeRendererFactory_h

#import <Foundation/Foundation.h>
#import "DanceUIComposeLogService.h"
#import "DanceUIComposeRenderingUIView.h"
#import "DanceUIComposeCanvas.h"
#import "DanceUIComposePaint.h"
#import "DanceUIComposeImageBitmap.h"
#import "DanceUIComposeFont.h"
#import "DanceUIComposeParagraphIntrinsics.h"
#import "DanceUIComposeAnnotatedStringRange.h"
#import "DanceUIComposeTextStyle.h"
#import "DanceUIComposeParagraph.h"
#import "DanceUIComposeRenderNodeLayer.h"
#import "DanceUIComposeAsyncImageLoader.h"
#import "DanceUIComposePathOps.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ComposeRendererFactory)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeRendererFactory <NSObject>

- (id<DanceUIComposeLogService>)getComposeLogService;

- (id<DanceUIComposeAsyncImageManager>)getComposeAsyncImageManager;

- (id<DanceUIComposeAsyncImageLoader>)makeComposeAsyncImageLoader;

- (UIView<DanceUIComposeRenderingUIView> *)makeComposeRenderingUIView:(id<DanceUIComposeRenderDelegate>)delegate;

- (id<DanceUIComposeCanvas>)makeComposeCanvas;

- (id<DanceUIComposeCanvas>)makeComposeCanvasWithVectorImage:(id<DanceUIComposeImageBitmap>)image;

- (id<DanceUIComposePaint>)makeComposePaint;

- (id<DanceUIComposeFontLoader>)makeComposeFontLoader;

// MARK: Paragraph

- (id<DanceUIComposeParagraphIntrinsics>)makeComposeParagraphIntrinsicsWithText:(NSString *)text
                                                                spanStyleRanges:(NSArray<id<DanceUIComposeAnnotatedStringRangeWithSpanStyle>> *)spanStyleRanges
                                                              placeholderRanges:(NSArray<id<DanceUIComposeAnnotatedStringRangeWithPlaceholder>> *)placeholderRanges
                                                                      textStyle:(id<DanceUIComposeTextStyle>)textStyle
                                                                 resourceLoader:(id<DanceUIComposeFontLoader>)fontLoader
                                                                       maxLines:(NSInteger)maxLines
                                                                       ellipsis:(BOOL)ellipsis;

- (id<DanceUIComposeParagraph>)makeComposeParagraphWithIntrinsics:(id<DanceUIComposeParagraphIntrinsics>)intrinsics
                                                           minWidth:(NSInteger)minWidth
                                                           maxWidth:(NSInteger)maxWidth
                                                          minHeight:(NSInteger)minHeight
                                                          maxHeight:(NSInteger)maxHeight
                                                           maxLines:(NSInteger)maxLines
                                                           ellipsis:(BOOL)ellipsis;

- (id<DanceUIComposeRenderNodeLayer>)makeComposeRenderNodeLayerWithIsItemRoot:(BOOL)isItemRoot;

- (id<DanceUIComposePathOps>)getComposePathOps;

- (void)dispatchMainTasks:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeRendererFactory_h */
