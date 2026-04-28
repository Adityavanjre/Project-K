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

/// A value with a modifier applied to it.
@frozen
@available(iOS 13.0, *)
public struct ModifiedContent<Content, Modifier> {

    /// The content that the modifier transforms into a new view or new
    /// view modifier.
    public var content: Content

    /// The view modifier.
    public var modifier: Modifier
    
    /// A structure that the defines the content and modifier needed to produce
    /// a new view or view modifier.
    ///
    /// If `content` is a ``View`` and `modifier` is a ``ViewModifier``, the
    /// result is a ``View``. If `content` and `modifier` are both view
    /// modifiers, then the result is a new ``ViewModifier`` combining them.
    ///
    /// - Parameters:
    ///     - content: The content that the modifier changes.
    ///     - modifier: The modifier to apply to the content.
    @inlinable
    public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }
    
    @inline(__always)
    internal func modifiedContent(_ body: (inout Content) -> ()) -> Self {
        var copy = self
        body(&copy.content)
        return copy
    }
    
    @inline(__always)
    internal func modifiedModifier(_ body: (inout Modifier) -> ()) -> Self {
        var copy = self
        body(&copy.modifier)
        return copy
    }
    
}

@available(iOS 13.0, *)
extension ModifiedContent: Equatable where Content : Equatable, Modifier : Equatable {
}

@available(iOS 13.0, *)
extension ModifiedContent: DynamicViewContent where Content : DynamicViewContent, Modifier : ViewModifier {

    /// The collection of underlying data.
    public var data: Content.Data {
        self.content.data
    }

    /// The type of the underlying collection of data.
    public typealias Data = Content.Data
}

@available(iOS 13.0, *)
extension ModifiedContent: ViewModifier where Content: ViewModifier, Modifier: ViewModifier {
    
    public typealias Body = Never
    
    @_semantics("optimize.sil.specialize.generic.never")
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
       
        return Modifier.makeDebuggableViewModifier(value: modifier[{ .of(&$0.modifier) }], inputs: inputs) { graph, inputs in
            Content.makeDebuggableViewModifier(value: modifier[{ .of(&$0.content) }], inputs: inputs) { graph, inputs in
                body(graph, inputs)
            }
        }
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    public static func _makeViewList(modifier: _GraphValue<ModifiedContent<Content, Modifier>>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        Modifier._makeViewList(modifier: modifier[{ .of(&$0.modifier) }], inputs: inputs) { graph, inputs in
            Content._makeViewList(modifier: modifier[{ .of(&$0.content) }], inputs: inputs, body: body)
        }
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs, body: @escaping (_ViewListCountInputs) -> Int?) -> Int? {
        Modifier._viewListCount(inputs: inputs) { internalInputs in
            Content._viewListCount(inputs: inputs, body: body)
        }
    }
}

@available(iOS 13.0, *)
extension ModifiedContent: View where Content: View, Modifier: ViewModifier {
    
    public typealias Body = Never
    
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that DanceUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    public var body: Never {
        bodyError()
    }
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        Modifier.makeDebuggableViewModifier(value: view[{ .of(&$0.modifier) }], inputs: inputs) { graph, inputs in
            Content.makeDebuggableView(value: view[{ .of(&$0.content) }], inputs: inputs)
        }
    }
    
    public static func _makeViewList(view: _GraphValue<ModifiedContent<Content, Modifier>>, inputs: _ViewListInputs) -> _ViewListOutputs {
        return Modifier._makeViewList(modifier: view[{ .of(&$0.modifier) }], inputs: inputs) { (graph, inputs) -> _ViewListOutputs in
            return Content._makeViewList(view: view[{ .of(&$0.content) }], inputs: inputs)
        }
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        Modifier._viewListCount(inputs: inputs) { internalInputs in
            Content._viewListCount(inputs: internalInputs)
        }
    }
}
