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
extension View {
    
    /// Adds an action to perform when this view appears.
    ///
    /// - Parameter action: The action to perform. If `action` is `nil`, the
    ///   call has no effect.
    ///
    /// - Returns: A view that triggers `action` when this view appears.
    @inlinable
    public func onAppear(perform action: (() -> Void)? = nil) -> some View {
        self.modifier(_AppearanceActionModifier(appear: action, disappear: nil))
    }
    
    
    /// Adds an action to perform when this view disappears.
    ///
    /// - Parameter action: The action to perform. If `action` is `nil`, the
    ///   call has no effect.
    ///
    /// - Returns: A view that triggers `action` when this view disappears.
    @inlinable
    public func onDisappear(perform action: (() -> Void)? = nil) -> some View {
        self.modifier(_AppearanceActionModifier(appear: nil, disappear: action))
    }
    
}
