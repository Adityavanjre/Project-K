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

import Foundation
import Darwin

/// Returns `true` if the property is got on main thread. Forwards to
/// `pthread_main_np()` on Drawin.
///
@inline(__always)
@available(iOS 13.0, *)
internal var isMainThread: Bool {
    pthread_main_np() != 0
}

/// Executes a closure immediately if the function is called on main thread,
/// else schedules it for execution on next run-loop of main thread.
///
@inline(__always)
@available(iOS 13.0, *)
internal func performOnMainThread(do body: @escaping () -> Void) {
    if isMainThread {
        body()
    } else {
        RunLoop.main.perform(inModes: [.common], block: body)
    }
}

@inline(__always)
@available(iOS 13.0, *)
internal func onNextMainRunLoop(do body: @escaping () -> Void) {
    RunLoop.main.perform(inModes: [.common], block: body)
}
