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
@_spi(DanceUI) import DanceUIObservation

/// A container view that defines its content as a function of its own size and
/// coordinate space.
///
/// This view returns a flexible preferred size to its parent layout.
@frozen
@available(iOS 13.0, *)
public struct GeometryReader<Content: View>: UnaryView, PrimitiveView {

    public var content: (GeometryProxy) -> Content

    @inlinable
    public init(@ViewBuilder content: @escaping (GeometryProxy) -> Content) {
        self.content = content
    }

    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = Never
    
    
    public static func _makeView(view: _GraphValue<GeometryReader<Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        let environment = inputs.environment
        
        let child = Child(view: view.value,
                          size: inputs.size,
                          position: inputs.position,
                          transform: inputs.transform,
                          environment: environment,
                          safeAreaInsets: inputs.safeAreaInsets,
                          seed: 0)
        
        let childAttribute = Attribute(child)

        childAttribute.flags = .removable
        
        let rootGeometry = RootGeometry(layoutDirection: .init(environment.layoutDirection), proposedSize: inputs.size, safeAreaInsets: .init(nil), childLayoutComputer: .init(nil))
        
        let rootGeometryAttribute = Attribute(rootGeometry)
        
        let origin = rootGeometryAttribute.origin()
        let viewOrigin = Attribute(LayoutPositionQuery(parentPosition: inputs.position, localPosition: origin))
        let size = rootGeometryAttribute.size()
        
        var newInputs = inputs
        
        newInputs.size = size
        newInputs.position = viewOrigin
        
        let graphValue = _GraphValue(childAttribute)
        
        
        var outputs = _VariadicView.Tree._makeView(view: graphValue, inputs: newInputs)
        rootGeometryAttribute.mutateBody(as: RootGeometry.self, invalidating: true) { body in
            body.$childLayoutComputer = outputs.layout.attribute
        }
        
        outputs.resetLayout()
        
        return outputs
    }
}

@available(iOS 13.0, *)
extension GeometryReader {
    
    internal struct Child: StatefulRule, ObservationAttribute {
        
        internal typealias Value = _VariadicView.Tree<GeometryReaderLayout, Content>
        
        @Attribute
        internal var view: GeometryReader<Content>
        
        @Attribute
        internal var size: ViewSize
        
        @Attribute
        internal var position: ViewOrigin
        
        @Attribute
        internal var transform: ViewTransform
        
        @Attribute
        internal var environment: EnvironmentValues
        
        @OptionalAttribute
        internal var safeAreaInsets: SafeAreaInsets?
        
        internal var seed: UInt32
                
        internal var previousObservationTrackings: [ObservationTracking]?
        
        internal var deferredObservationGraphMutation: DeferredObservationGraphMutation?
        
        internal mutating func updateValue() {
            let weakAttribute = WeakAttribute(context.attribute)
            let weakSize = WeakAttribute(self._size)
            let weakEnvironment = WeakAttribute(self._environment)
            let weakTransform = WeakAttribute(self._transform)
            let weakPosition = WeakAttribute(self._position)
            let weakSafeAreaInsets = WeakAttribute(self._safeAreaInsets.attribute)
            let proxy = GeometryProxy(owner: weakAttribute.base, _size: weakSize, _environment: weakEnvironment, _transform: weakTransform, _position: weakPosition, _safeAreaInsets: weakSafeAreaInsets, _seed: self.seed &+ 1)
            
            let (view, isViewChanged) = $view.changedValue()
            
            let content = withObservation(shouldCancelPrevious: isViewChanged) {
                view.content(proxy)
            }
            
            self.value = _VariadicView.Tree(root: GeometryReaderLayout(), content: content)
        }
    }
}
