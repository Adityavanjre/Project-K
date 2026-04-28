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

@available(iOS 13.0, *)
extension Gesture {
    
    /// Adds an action to perform when the gesture failed.
    ///
    /// - Parameter action: The action to perform when this gesture faield.
    ///
    /// - Returns: A gesture that triggers `action` when this gesture failed.
    /// 
    /// - Notes: `Gesture.onFailed` is makred public because DanceUI's gesture
    /// cannot prevent itself from recognition when the home indiactor's
    /// swipe-up-to-show-task-manager gesture is recognized -- developer's
    /// codes are not able to be aware of this gesture's recognition. The only
    /// solution is to make the developer know that it's gesture is failed at
    /// that time.
    ///
    @inline(__always)
    public func onFailed(do body: @escaping () -> Void) -> some Gesture {
        callbacks(FailedCallbacks<Value>(failed: body))
    }
    
}

@available(iOS 13.0, *)
internal struct FailedCallbacks<A>: GestureCallbacks {
    
    internal typealias StateType = Void
    
    internal typealias Value = A
    
    internal let failed: () -> ()
    
    internal static var initialState: Void { () }
    
    internal func dispatch(phase: GesturePhase<A>, state: inout Void) -> (() -> ())? {
        guard case .failed = phase else {
            return nil
        }
        return failed
    }
    
    internal func cancel(state: Void) -> (() -> ())? {
        failed
    }
}
