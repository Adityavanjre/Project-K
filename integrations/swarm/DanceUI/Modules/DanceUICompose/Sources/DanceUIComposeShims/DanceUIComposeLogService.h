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

#ifndef DanceUIComposeLog_h
#define DanceUIComposeLog_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DanceUIComposeLogPriority) {
    DanceUIComposeLogPriorityTrace,
    DanceUIComposeLogPriorityDebug,
    DanceUIComposeLogPriorityInfo,
    DanceUIComposeLogPriorityNotice,
    DanceUIComposeLogPriorityWarning,
    DanceUIComposeLogPriorityError,
    DanceUIComposeLogPriorityCritical
} NS_SWIFT_NAME(ComposeLogPriority);

typedef NSString *DanceUIComposeLogKeyword NS_STRING_ENUM NS_SWIFT_NAME(ComposeLogKeyword);

FOUNDATION_EXPORT DanceUIComposeLogKeyword const DanceUIComposeLogKeywordCanvas;
FOUNDATION_EXPORT DanceUIComposeLogKeyword const DanceUIComposeLogKeywordPaint;
FOUNDATION_EXPORT DanceUIComposeLogKeyword const DanceUIComposeLogKeywordImageBitmap;
FOUNDATION_EXPORT DanceUIComposeLogKeyword const DanceUIComposeLogKeywordRenderingView;
FOUNDATION_EXPORT DanceUIComposeLogKeyword const DanceUIComposeLogKeywordRenderNodeLayer;
FOUNDATION_EXPORT DanceUIComposeLogKeyword const DanceUIComposeLogKeywordParagraph;

NS_SWIFT_NAME(ComposeLogService)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeLogService <NSObject>

- (void)logWithPriority:(DanceUIComposeLogPriority)priority
                keyword:(DanceUIComposeLogKeyword)keyword
                message:(NSString *)message
                   info:(NSDictionary<NSString *, id> *)info;


@end


NS_ASSUME_NONNULL_END

#endif /* DanceUIComposeLog_h */
