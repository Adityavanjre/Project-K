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

#ifndef DanceUIComposeBreakiterator_h
#define DanceUIComposeBreakiterator_h

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ComposeBreakIterator)
@protocol DanceUIComposeBreakIterator <NSObject>

+ (instancetype)makeCharacterInstanceLocale:(NSString * _Nullable)locale NS_SWIFT_NAME(makeCharacterInstance(locale:));
- (void)setText:(NSString *)string;
- (BOOL)isBoundary:(int32_t)offset NS_SWIFT_NAME(isBoundary(offset:));
- (int32_t)preceding:(int32_t)offset NS_SWIFT_NAME(preceding(offset:));
- (int32_t)following:(int32_t)offset NS_SWIFT_NAME(following(offset:));
- (int32_t)current;
- (int32_t)next;
- (int32_t)next:(int32_t)index NS_SWIFT_NAME(next(index:));
@end


NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeBreakiterator_h */
