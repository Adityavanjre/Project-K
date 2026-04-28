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
#import <CoreGraphics/CGColorSpace.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DanceUIComposeAnimatedImageState) {
    DanceUIComposeAnimatedImageStatePlay,
    DanceUIComposeAnimatedImageStatePause,
    DanceUIComposeAnimatedImageStateStop
} NS_AVAILABLE_IOS(13_0) NS_SWIFT_NAME(ComposeAnimatedImageState);

typedef NS_ENUM(NSInteger, DanceUIComposeAnimatedImagePlayType) {
    DanceUIComposeAnimatedImagePlayTypeOrder,
    DanceUIComposeAnimatedImagePlayTypeReciprocating
} NS_AVAILABLE_IOS(13_0) NS_SWIFT_NAME(ComposeAnimatedImagePlayType);

NS_SWIFT_NAME(ComposeAnimatedImageConfig)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeAnimatedImageConfig <NSObject>

@property (nonatomic, assign) DanceUIComposeAnimatedImageState playState;
@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) BOOL autoStop;
@property (nonatomic, assign) BOOL infinityLoop;
@property (nonatomic, assign) NSUInteger customLoop;
@property (nonatomic, assign) DanceUIComposeAnimatedImagePlayType animationType;
@property (nonatomic, copy, nullable) void (^onImageAnimateStart)(void);
@property (nonatomic, copy, nullable) void (^onImageAnimateEnd)(void);

@end

typedef NS_ENUM(NSInteger, DanceUIComposeImageBitmapConfig) {
    DanceUIComposeImageBitmapConfigARGB8888,
    DanceUIComposeImageBitmapConfigAlpha8,
    DanceUIComposeImageBitmapConfigRGB565
} NS_AVAILABLE_IOS(13_0) NS_SWIFT_NAME(ComposeImageBitmapConfig);

typedef NS_ENUM(NSInteger, DanceUIComposeImageBitmapType) {
    DanceUIComposeImageBitmapUIImage,
    DanceUIComposeImageBitmapVector,
} NS_AVAILABLE_IOS(13_0) NS_SWIFT_NAME(ComposeImageBitmapType);

NS_SWIFT_NAME(ComposeImageBitmap)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeImageBitmap <NSObject>

@property (nonatomic, readonly) NSInteger width;
@property (nonatomic, readonly) NSInteger height;
@property (nonatomic, readonly) CGColorSpaceRef colorSpace;
@property (nonatomic, readonly) BOOL hasAlpha;
@property (nonatomic, readonly) DanceUIComposeImageBitmapConfig config;
@property (nonatomic, readonly) DanceUIComposeImageBitmapType type;

- (void)setupWithConfig:(id<DanceUIComposeAnimatedImageConfig>)config;

@end

NS_ASSUME_NONNULL_END
