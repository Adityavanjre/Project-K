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
    /// Modifies the fonts of all child views to use fixed-width digits, if
    /// possible, while leaving other characters proportionally spaced.
    ///
    /// Using fixed-width digits allows you to easily align numbers of the
    /// same size in a table-like arrangement. This feature is also known as
    /// "tabular figures" or "tabular numbers."
    ///
    /// This modifier only affects numeric characters, and leaves all other
    /// characters unchanged.
    ///
    /// The following example shows the effect of `monospacedDigit()` on
    /// multiple child views. The example consists of two ``VStack`` views
    /// inside an ``HStack``. Each `VStack` contains two ``Button`` views, with
    /// the second `VStack` applying the `monospacedDigit()` modifier to its
    /// contents. As a result, the digits in the buttons in the trailing
    /// `VStack` are the same width, which in turn gives the buttons equal widths.
    ///
    ///     var body: some View {
    ///         HStack(alignment: .top) {
    ///             VStack(alignment: .leading) {
    ///                 Button("Delete 111 messages") {}
    ///                 Button("Delete 222 messages") {}
    ///             }
    ///             VStack(alignment: .leading) {
    ///                 Button("Delete 111 messages") {}
    ///                 Button("Delete 222 messages") {}
    ///             }
    ///             .monospacedDigit()
    ///         }
    ///         .padding()
    ///         .navigationTitle("monospacedDigit() Child Views")
    ///     }
    ///
    ///
    /// If a child view's base font doesn't support fixed-width digits, the font
    /// remains unchanged.
    ///
    /// - Returns: A view whose child views' fonts use fixed-width numeric
    /// characters, while leaving other characters proportionally spaced.
    public func monospacedDigit() -> some View {
        appendEnvironmentFontModifier(modifier: .static(type: Font.MonospacedDigitModifier.self))
    }

    /// Modifies the fonts of all child views to use the fixed-width variant of
    /// the current font, if possible.
    ///
    /// If a child view's base font doesn't support fixed-width, the font
    /// remains unchanged.
    ///
    /// - Returns: A view whose child views' fonts use fixed-width characters,
    /// while leaving other characters proportionally spaced.
    public func monospaced(_ isActive: Bool = true) -> some View {
        appendEnvironmentFontModifier(modifier: .static(type: Font.MonospacedModifier.self), isActive: isActive)
    }

    /// Sets the font weight of the text in this view.
    ///
    /// - Parameter weight: One of the available font weights.
    ///   Providing `nil` removes the effect of any font weight
    ///   modifier applied higher in the view hierarchy.
    ///
    /// - Returns: A view that uses the font weight you specify.
    @ViewBuilder
    public func fontWeight(_ weight: Font.Weight?) -> some View {        
        if let weight {
            transformEnvironment(\.fontModifiers) { value in
                value.append(.dynamic(modifier: Font.WeightModifier(weight: weight)))
            }
        } else {
            transformEnvironment(\.fontModifiers) { value in
                value = value.filter { value in
                    !(value is AnyDynamicFontModifier<Font.WeightModifier>) && !value.isEqual(to: .static(type: Font.BoldModifier.self))
                }
            }
        }
    }

    /// Applies a bold font weight to the text in this view.
    ///
    /// - Parameter isActive: A Boolean value that indicates
    ///   whether bold font styling is added. The default value is `true`.
    ///
    /// - Returns: A view with bold text.
    public func bold(_ isActive: Bool = true) -> some View {
        appendEnvironmentFontModifier(modifier: .static(type: Font.BoldModifier.self), isActive: isActive)
    }


    /// Applies italics to the text in this view.
    ///
    /// - Parameter isActive: A Boolean value that indicates
    ///   whether italic styling is added. The default value is `true`.
    ///
    /// - Returns: A View with italic text.
    public func italic(_ isActive: Bool = true) -> some View {
        appendEnvironmentFontModifier(modifier: .static(type: Font.ItalicModifier.self), isActive: isActive)
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Applies an underline to the text in this view.
    ///
    /// - Parameters:
    ///   - isActive: A Boolean value that indicates whether underline
    ///     is added. The default value is `true`.
    ///   - pattern: The pattern of the line. The default value is `solid`.
    ///   - color: The color of the underline. If `color` is `nil`, the
    ///     underline uses the default foreground color.
    ///
    /// - Returns: A view where text has a line running along its baseline.
    public func underline(_ isActive: Bool = true, color: Color? = nil) -> some View {
        environment(\.underlineStyle, isActive ? Text.LineStyle(nsUnderlineStyle: .single, color: color) : nil)
    }


    /// Applies a strikethrough to the text in this view.
    ///
    /// - Parameters:
    ///   - isActive: A Boolean value that indicates whether
    ///     strikethrough is added. The default value is `true`.
    ///   - pattern: The pattern of the line. The default value is `solid`.
    ///   - color: The color of the strikethrough. If `color` is `nil`, the
    ///     strikethrough uses the default foreground color.
    ///
    /// - Returns: A view where text has a line through its center.
    public func strikethrough(_ isActive: Bool = true, color: Color? = nil) -> some View {
        environment(\.strikethroughStyle, isActive ? Text.LineStyle(nsUnderlineStyle: .single, color: color) : nil)
    }
}

@available(iOS 13.0, *)
extension View {
    
    @inline(__always)
    private func appendEnvironmentFontModifier(modifier: AnyFontModifier, isActive: Bool = true) -> some View {
        if isActive {
            transformEnvironment(\.fontModifiers) { value in
                value.append(modifier)
            }
        } else {
            transformEnvironment(\.fontModifiers) { value in
                value = value.filter { value in
                    !value.isEqual(to: modifier)
                }
            }
        }
    }
}
