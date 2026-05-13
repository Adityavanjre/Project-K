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
    ///
    ///  Sets the color of the foreground elements displayed by this view.
    ///
    /// - Parameter color: The foreground color to use when displaying this
    ///   view. Pass `nil` to remove any custom foreground color and to allow
    ///   the system or the container to provide its own foreground color.
    ///   If a container-specific override doesn't exist, the system uses
    ///   the primary color.
    ///
    /// - Returns: A view that uses the foreground color you supply.
    @inlinable
    public func foregroundColor(_ color: Color?) -> some View {
        return environment(\.foregroundColor, color)
    }
}

@available(iOS 13.0, *)
extension View {
    @inline(__always)
    internal func defaultForegroundColor(_ color: Color) -> some View {
        return environment(\.defaultForegroundColor, color)
    }

    @inline(__always)
    internal func defaultForegroundColor(_ color: Color?) -> some View {
        return environment(\.defaultForegroundColor, color)
    }
}
