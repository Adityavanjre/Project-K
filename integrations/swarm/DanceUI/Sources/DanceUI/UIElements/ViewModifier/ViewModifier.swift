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
internal import DanceUIGraph

/// A modifier that you apply to a view or another view modifier, producing a
/// different version of the original value.
///
/// Adopt the ``ViewModifier`` protocol when you want to create a reusable
/// modifier that you can apply to any view. The example below combines several
/// modifiers to create a new modifier that you can use to create blue caption
/// text surrounded by a rounded rectangle:
///
///     struct BorderedCaption: ViewModifier {
///         func body(content: Content) -> some View {
///             content
///                 .font(.caption2)
///                 .padding(10)
///                 .overlay(
///                     RoundedRectangle(cornerRadius: 15)
///                         .stroke(lineWidth: 1)
///                 )
///                 .foregroundColor(Color.blue)
///         }
///     }
///
/// You can apply ``View/modifier(_:)`` directly to a view, but a more common
/// and idiomatic approach uses ``View/modifier(_:)`` to define an extension to
/// ``View`` itself that incorporates the view modifier:
///
///     extension View {
///         func borderedCaption() -> some View {
///             modifier(BorderedCaption())
///         }
///     }
///
/// You can then apply the bordered caption to any view, similar to this:
///
///     Image(systemName: "bus")
///         .resizable()
///         .frame(width:50, height:50)
///     Text("Downtown Bus")
///         .borderedCaption()
///
@available(iOS 13.0, *)
public protocol ViewModifier {
    
    /// The type of view representing the body.
    associatedtype Body : View
    
    @ViewBuilder
    func body(content: Self.Content) -> Self.Body
    
    typealias Content = _ViewModifier_Content<Self>
    
    static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs
    
    static func _makeViewList(modifier: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs
    
    static func _viewListCount(inputs: _ViewListCountInputs,  body: @escaping (_ViewListCountInputs) -> Int?) -> Int?

}

@available(iOS 13.0, *)
extension ViewModifier where Self.Body == Never {
    
    /// Gets the current body of the caller.
    ///
    /// `content` is a proxy for the view that will have the modifier
    /// represented by `Self` applied to it.
    public func body(content: Self.Content) -> Self.Body {
        _danceuiFatalError()
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs, body: @escaping (_ViewListCountInputs) -> Int?) -> Int? {
        body(inputs)
    }
}

@available(iOS 13.0, *)
extension ViewModifier {
    
    /// Returns a new modifier that is the result of concatenating
    /// `self` with `modifier`.
    @inlinable
    public func concat<T>(_ modifier: T) -> ModifiedContent<Self, T> {
        ModifiedContent(content: self, modifier: modifier)
    }
}

@available(iOS 13.0, *)
extension ViewModifier where Self : _GraphInputsModifier, Self.Body == Never {
    
    @_semantics("optimize.sil.specialize.generic.never")
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var newInputs = inputs
        let _ = withMutableViewInputs(&newInputs) { base in
            _makeInputs(modifier: modifier, inputs: &base)
        }
        let outputs: _ViewOutputs = body(_Graph(), newInputs)
        return outputs
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    public static func _makeViewList(modifier: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        var newInputs = inputs
        let _ = newInputs.withMutableGraphInputs { base in
            _makeInputs(modifier: modifier, inputs: &base)
        }
        return body(_Graph(), newInputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs, body: @escaping (_ViewListCountInputs) -> Int?) -> Int? {
        body(inputs)
    }
    
}
