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
#import "DanceUIVersionManager.h"
#import <DanceUIRuntime/DanceUIRuntimeVersionManager.h>
#import <DanceUIGraph/DanceUIGraphVersionManager.h>

#ifndef DanceUI_POD_VERSION
#define DanceUI_POD_VERSION @"(Undefined Version)"
#endif

#ifndef DanceUI_COMMIT_ID
#define DanceUI_COMMIT_ID @"(Undefined Commit Id)"
#endif

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT
NSString *const DanceUIVersion = DanceUI_POD_VERSION;

FOUNDATION_EXPORT
NSString *const DanceUICommitId = DanceUI_COMMIT_ID;

static NSString *getFullVersionMessage(NSString *podName, NSString *podVersion, NSString *podCommitId);

static NSString *getDanceUIVersionFromDownStreamPod(NSString *podName, NSString *podVersionClassName);

FOUNDATION_EXPORT
NSString *_DanceUIGetVersion(void) {
    return [NSString stringWithFormat:@"%@\r%@\r%@\r%@\r",
            getFullVersionMessage(@"DanceUI", DanceUIVersion, DanceUICommitId),
            getDanceUIVersionFromDownStreamPod(@"DanceUIExtension", @"DanceUIExtensionVersionManager"),
            getFullVersionMessage(@"DanceUIGraph", DanceUIGraphVersion, DanceUIGraphCommitId),
            getFullVersionMessage(@"DanceUIRuntime", DanceUIRuntimeVersion, DanceUIRuntimeCommitId)];
}

static NSString *getFullVersionMessage(NSString *podName, NSString *podVersion, NSString *podCommitId) {
    NSString *formatedPodVersion = [podVersion stringByReplacingOccurrencesOfString:@"9999_" withString:@""];
    return [NSString stringWithFormat:@"%@:\t%@, %@", podName, formatedPodVersion, podCommitId];
}

static NSString *getDanceUIVersionFromDownStreamPod(NSString *podName, NSString *podVersionClassName) {
    Class clazz = NSClassFromString(podVersionClassName);
    NSString *versionRaw;
    if ([clazz respondsToSelector:@selector(version)]) {
        versionRaw = [clazz performSelector:@selector(version)];
    } else {
        versionRaw = @"(Undefined Version)"; // BDCOV_EXCL_LINE
    } // BDCOV_EXCL_LINE
    NSString *commitIdRaw;
    if ([clazz respondsToSelector:@selector(commitId)]) {
        commitIdRaw = [clazz performSelector:@selector(commitId)];
    } else {
        commitIdRaw = @"(Undefined Commit Id)"; // BDCOV_EXCL_LINE
    } // BDCOV_EXCL_LINE
    return getFullVersionMessage(podName, versionRaw, commitIdRaw);
}

NS_ASSUME_NONNULL_END

