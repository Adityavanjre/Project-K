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

internal import DanceUIGraph

/// A type that represents part of your app's user interface and provides
/// modifiers that you use to configure views.
///
/// You create custom views by declaring types that conform to the `View`
/// protocol. Implement the required ``View/body-swift.property`` computed
/// property to provide the content for your custom view.
///
///     struct MyView: View {
///         var body: some View {
///             Text("Hello, World!")
///         }
///     }
///
/// Assemble the view's body by combining one or more of the built-in views
/// provided by DanceUI, like the ``Text`` instance in the example above, plus
/// other custom views that you define, into a hierarchy of views. For more
/// information about creating custom views, see <doc:Declaring-a-Custom-View>.
///
/// The `View` protocol provides a set of modifiers — protocol
/// methods with default implementations — that you use to configure
/// views in the layout of your app. Modifiers work by wrapping the
/// view instance on which you call them in another view with the specified
/// characteristics, as described in <doc:Configuring-Views>.
/// For example, adding the ``View/opacity(_:)`` modifier to a
/// text view returns a new view with some amount of transparency:
///
///     Text("Hello, World!")
///         .opacity(0.5) // Display partially transparent text.
///
/// The complete list of default modifiers provides a large set of controls
/// for managing views.
/// For example, you can fine tune <doc:View-Layout>,
/// add <doc:View-Accessibility> information,
/// and respond to <doc:View-Input-and-Events>.
/// You can also collect groups of default modifiers into new,
/// custom view modifiers for easy reuse.
@available(iOS 13.0, *)
public protocol View {

    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required `body` property.
    associatedtype Body : View

    static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs
    
    static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs
    
    static func _viewListCount(inputs: _ViewListCountInputs) -> Int?
    
    @ViewBuilder
    @MainActor @preconcurrency
    var body: Self.Body { get }

}

@available(iOS 13.0, *)
extension View {
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        makeView(view: view, inputs: inputs)
    }
    
    public static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        makeViewList(view: view, inputs: inputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        Body._viewListCount(inputs: inputs)
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    internal static func makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        let fields = DynamicPropertyCache.fields(of: self)
        
        var bodyInputs = inputs
        
        let (descendantView, propertyBufferOrNil) = withMutableViewInputs(&bodyInputs) { base in
            makeBody(view: view,
                     inputs: &base,
                     fields: fields)
        }
        
        let outputs = Body.makeDebuggableView(value: descendantView, inputs: bodyInputs)
        
        if let propertyBuffer = propertyBufferOrNil {
            propertyBuffer.traceMountedProperties(to: view, fields: fields)
        }
        
        return outputs
    }

    @_semantics("optimize.sil.specialize.generic.never")
    internal static func makeViewList(view: _GraphValue<Self>,
                                        inputs: _ViewListInputs) -> _ViewListOutputs {
        let fields = DynamicPropertyCache.fields(of: self)
        
        var bodyInputs = inputs
        let (decendantView, propertyBufferOrNil) = bodyInputs.withMutableGraphInputs { base in
            makeBody(view: view,
                     inputs: &base,
                     fields: fields)
        }
        let outputs = Body._makeViewList(view: decendantView,
                                           inputs: bodyInputs)
        
        if let propertyBuffer = propertyBufferOrNil {
            propertyBuffer.traceMountedProperties(to: view, fields: fields)
        }
        return outputs
    }
    
    internal static func makeImplicitRoot(view: _GraphValue<Self>,
                                          inputs: _ViewInputs) -> _ViewOutputs {
        func body(_ graph: _Graph, viewInputs: _ViewInputs) -> _ViewListOutputs {
            let viewListInputs = _ViewListInputs(base: viewInputs.base,
                                                   implicitID: 0,
                                                   options: viewInputs.viewListOptions,
                                                   traitKeys: ViewTraitKeys())
            return _makeViewList(view: view, inputs: viewListInputs)
        }
        
        let ImplicitRootType = inputs.implicitRootType
        var visitor = MakeViewRoot(inputs: inputs, body: body)
        ImplicitRootType.visitType(visitor: &visitor.self)
        
        guard let outputs = visitor.outputs else {
            _danceuiPreconditionFailure()
        }
        
        return outputs
    }
    
    fileprivate static func makeBody(view: _GraphValue<Self>, inputs: inout _GraphInputs, fields: DynamicPropertyCache.Fields) -> (_GraphValue<Body>, _DynamicPropertyBuffer?) {
        let kind = DGTypeID(Self.self).kind
        guard kind.isOfValueTypes else {
            _danceuiFatalError("\(_typeName(Self.self)) is a class.")
        }
        return ViewBodyAccessor<Self>().makeBody(container: view,
                                                 inputs: &inputs,
                                                 fields: fields)
        
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    internal func bodyError() -> Never {
        _terminatedViewNode()
    }
    
}

