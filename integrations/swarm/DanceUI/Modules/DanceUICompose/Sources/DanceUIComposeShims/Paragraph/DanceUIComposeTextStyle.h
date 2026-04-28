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

#ifndef DanceUIComposeTextStyle_h
#define DanceUIComposeTextStyle_h

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeParagraphStyle;
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeSpanStyle;

// MARK: - TextStyle Protocol

NS_SWIFT_NAME(ComposeTextStyle)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeTextStyle <NSObject>

@property (nonatomic, readonly) id<DanceUIComposeSpanStyle> spanStyle;
@property (nonatomic, readonly) id<DanceUIComposeParagraphStyle> paragraphStyle;

@end

NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeTextStyle_h */
