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
    
    /// Sets the accent color for this view and the views it contains.
    ///
    /// Use `accentColor(_:)` when you want to apply a broad theme color to
    /// your app's user interface. Some styles of controls use the accent color
    /// as a default tint color.
    ///
    /// > Note: In macOS, DanceUI applies customization of the accent color
    /// only if the user chooses Multicolor under General > Accent color
    /// in System Preferences.
    ///
    /// In the example below, the outer ``VStack`` contains two child views. The
    /// first is a button with the default accent color. The second is a ``VStack``
    /// that contains a button and a slider, both of which adopt the purple
    /// accent color of their containing view. Note that the ``Text`` element
    /// used as a label alongside the `Slider` retains its default color.
    ///
    ///     VStack(spacing: 20) {
    ///         Button(action: {}) {
    ///             Text("Regular Button")
    ///         }
    ///         VStack {
    ///             Button(action: {}) {
    ///                 Text("Accented Button")
    ///             }
    ///             HStack {
    ///                 Text("Accented Slider")
    ///                 Slider(value: $sliderValue, in: -100...100, step: 0.1)
    ///             }
    ///         }
    ///         .accentColor(.purple)
    ///     }
    ///
    ///
    /// - Parameter accentColor: The color to use as an accent color. Set the
    ///   value to `nil` to use the inherited accent color.
    ///
    @inlinable
    public func accentColor(_ accentColor: Color?) -> some View {
        return environment(\.accentColor, accentColor)
    }
    
}
