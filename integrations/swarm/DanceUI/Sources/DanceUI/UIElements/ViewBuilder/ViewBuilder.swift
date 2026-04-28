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

/// A custom parameter attribute that constructs views from closures.
///
/// You typically use ``ViewBuilder`` as a parameter attribute for child
/// view-producing closure parameters, allowing those closures to provide
/// multiple child views. For example, the following `contextMenu` function
/// accepts a closure that produces one or more views via the view builder.
///
///     func contextMenu<MenuItems: View>(
///         @ViewBuilder menuItems: () -> MenuItems
///     ) -> some View
///
/// Clients of this function can use multiple-statement closures to provide
/// several child views, as shown in the following example:
///
///     myView.contextMenu {
///         Text("Cut")
///         Text("Copy")
///         Text("Paste")
///         if isSymbol {
///             Text("Jump to Definition")
///         }
///     }
///
@resultBuilder
@available(iOS 13.0, *)
public struct ViewBuilder {
    
    /// Builds an expression within the builder.
    @_alwaysEmitIntoClient
    public static func buildExpression<Content>(_ content: Content) -> Content where Content : View {
        content
    }

    /// Builds an empty view from a block containing no statements.
    @_alwaysEmitIntoClient
    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    /// Passes a single view written as a child view through unmodified.
    ///
    /// An example of a single view written as a child view is
    /// `{ Text("Hello") }`.
    @_alwaysEmitIntoClient
    public static func buildBlock<Content>(_ content: Content) -> Content where Content : View {
        content
    }
    
#if compiler(>=5.3) && $ParameterPacks
    @_disfavoredOverload 
    @_alwaysEmitIntoClient
    public static func buildBlock<each Content>(_ content: repeat each Content) -> TupleView<(repeat each Content)> where repeat each Content : View {
        TupleView((repeat each content))
    }
#endif
}

@available(iOS 13.0, *)
extension ViewBuilder {
    
    /// Provides support for "if" statements with `#available()` clauses in
    /// multi-statement closures, producing conditional content for the "then"
    /// branch, i.e. the conditionally-available branch.
    @_alwaysEmitIntoClient
    public static func buildLimitedAvailability<Content>(_ content: Content) -> AnyView where Content : View {
        content.eraseToAnyView()
    }
}

@available(iOS 13.0, *)
extension ViewBuilder {

    /// Provides support for “if” statements in multi-statement closures,
    /// producing an optional view that is visible only when the condition
    /// evaluates to `true`.
    @_alwaysEmitIntoClient
    public static func buildIf<Content>(_ content: Content?) -> Content? where Content : View {
        content
    }

    /// Provides support for "if" statements in multi-statement closures,
    /// producing conditional content for the "then" branch.
    @_alwaysEmitIntoClient
    public static func buildEither<TrueContent, FalseContent>(first: TrueContent) -> _ConditionalContent<TrueContent, FalseContent> where TrueContent : View, FalseContent : View {
        _ConditionalContent(storage: .trueContent(first))
    }

    /// Provides support for "if" statements in multi-statement closures,
    /// producing conditional content for the "then" branch.
    @_alwaysEmitIntoClient
    public static func buildEither<TrueContent, FalseContent>(second: FalseContent) -> _ConditionalContent<TrueContent, FalseContent> where TrueContent : View, FalseContent : View {
        _ConditionalContent(storage: .falseContent(second))
    }
}

#if compiler(<5.3) || !$ParameterPacks

@available(iOS 13.0, *)
extension ViewBuilder {

    @_alwaysEmitIntoClient
    public static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> TupleView<(C0, C1)> where C0 : View, C1 : View {
        .init((c0, c1))
    }
    
}

@available(iOS 13.0, *)
extension ViewBuilder {

    @_alwaysEmitIntoClient
    public static func buildBlock<C0, C1, C2>(_ c0: C0, _ c1: C1, _ c2: C2) -> TupleView<(C0, C1, C2)> where C0 : View, C1 : View, C2 : View {
        .init((c0, c1, c2))
    }
    
}

@available(iOS 13.0, *)
extension ViewBuilder {

    @_alwaysEmitIntoClient
    public static func buildBlock<C0, C1, C2, C3>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> TupleView<(C0, C1, C2, C3)> where C0 : View, C1 : View, C2 : View, C3 : View {
        .init((c0, c1, c2, c3))
    }
    
}

@available(iOS 13.0, *)
extension ViewBuilder {

    @_alwaysEmitIntoClient
    public static func buildBlock<C0, C1, C2, C3, C4>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> TupleView<(C0, C1, C2, C3, C4)> where C0 : View, C1 : View, C2 : View, C3 : View, C4 : View {
        .init((c0, c1, c2, c3, c4))
    }
    
}

@available(iOS 13.0, *)
extension ViewBuilder {

    @_alwaysEmitIntoClient
    public static func buildBlock<C0, C1, C2, C3, C4, C5>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5) -> TupleView<(C0, C1, C2, C3, C4, C5)> where C0 : View, C1 : View, C2 : View, C3 : View, C4 : View, C5 : View {
        .init((c0, c1, c2, c3, c4, c5))
    }
    
}

@available(iOS 13.0, *)
extension ViewBuilder {

    @_alwaysEmitIntoClient
    public static func buildBlock<C0, C1, C2, C3, C4, C5, C6>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6) -> TupleView<(C0, C1, C2, C3, C4, C5, C6)> where C0 : View, C1 : View, C2 : View, C3 : View, C4 : View, C5 : View, C6 : View {
        .init((c0, c1, c2, c3, c4, c5, c6))
    }
    
}

@available(iOS 13.0, *)
extension ViewBuilder {

    @_alwaysEmitIntoClient
    public static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7) -> TupleView<(C0, C1, C2, C3, C4, C5, C6, C7)> where C0 : View, C1 : View, C2 : View, C3 : View, C4 : View, C5 : View, C6 : View, C7 : View {
        .init((c0, c1, c2, c3, c4, c5, c6, c7))
    }
    
}

@available(iOS 13.0, *)
extension ViewBuilder {

    @_alwaysEmitIntoClient
    public static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7, C8>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8) -> TupleView<(C0, C1, C2, C3, C4, C5, C6, C7, C8)> where C0 : View, C1 : View, C2 : View, C3 : View, C4 : View, C5 : View, C6 : View, C7 : View, C8 : View {
        .init((c0, c1, c2, c3, c4, c5, c6, c7, c8))
    }
    
}

@available(iOS 13.0, *)
extension ViewBuilder {

    @_alwaysEmitIntoClient
    public static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9) -> TupleView<(C0, C1, C2, C3, C4, C5, C6, C7, C8, C9)> where C0 : View, C1 : View, C2 : View, C3 : View, C4 : View, C5 : View, C6 : View, C7 : View, C8 : View, C9 : View {
        .init((c0, c1, c2, c3, c4, c5, c6, c7, c8, c9))
    }
    
}
#endif // compiler(<5.3) || $ParameterPacks
