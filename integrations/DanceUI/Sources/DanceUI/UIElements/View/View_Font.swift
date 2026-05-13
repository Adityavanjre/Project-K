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
    /// Sets the default font for text in this view.
    ///
    /// Use `font(_:)` to apply a specific font to all of the text in a view.
    ///
    /// The example below shows the effects of applying fonts to individual
    /// views and to view hierarchies. Font information flows down the view
    /// hierarchy as part of the environment, and remains in effect unless
    /// overridden at the level of an individual view or view container.
    ///
    /// Here, the outermost ``VStack`` applies a 16-point system font as a
    /// default font to views contained in that ``VStack``. Inside that stack,
    /// the example applies a ``Font/largeTitle`` font to just the first text
    /// view; this explicitly overrides the default. The remaining stack and the
    /// views contained with it continue to use the 16-point system font set by
    /// their containing view:
    ///
    ///     VStack {
    ///         Text("Font applied to a text view.")
    ///             .font(.largeTitle)
    ///
    ///         VStack {
    ///             Text("These 2 text views have the same font")
    ///             Text("applied to their parent hierarchy")
    ///         }
    ///     }
    ///     .font(.system(size: 16, weight: .light, design: .default))
    ///
    ///
    /// - Parameter font: The default font to use in this view.
    ///
    /// - Returns: A view with the default font set to the value you supply.
    @inlinable
    @inline(__always)
    public func font(_ font: Font?) -> some View {
        environment(\.font, font)
    }
}

@available(iOS 13.0, *)
extension View {
    @inline(__always)
    internal func defaultFont(_ font: Font?) -> some View {
        environment(\.defaultFont, font)
    }
}
