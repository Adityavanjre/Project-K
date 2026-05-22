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

@available(iOS 13.0, *)
extension View {
    
    /// Configures whether this view participates in hit test operations.
    @inlinable
    public func allowsHitTesting(_ enabled: Bool) -> some View {
        return modifier(_AllowsHitTestingModifier(allowsHitTesting: enabled))
    }
    
}

@frozen
@available(iOS 13.0, *)
public struct _AllowsHitTestingModifier: PrimitiveViewModifier, MultiViewModifier, Equatable, RendererEffect {
    
    public typealias Body = Never
    
    public var allowsHitTesting: Bool
    
    @inlinable
    public init(allowsHitTesting: Bool) {
        self.allowsHitTesting = allowsHitTesting
    }
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .properties( !allowsHitTesting ? .isHitTestingDisabled : .empty)
    }
    
    public static func _makeView(modifier: _GraphValue<_AllowsHitTestingModifier>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        let newInputs = _ViewInputs(deepCopy: inputs)
        var output = makeRendererEffect(effect: modifier, inputs: newInputs, body: body)
        if newInputs.preferences.requiresViewResponders {
            let emptyViewResponder = (ViewGraph.currentHost as! ViewGraph).$emptyViewResponders
            let viewResponders = output.viewResponders ?? emptyViewResponder
            let hitTestingResponder = AllowsHitTestingResponder(inputs: inputs)
            
            let filter = Attribute(
                AllowsHitTestingFilter(
                    modifier: modifier.value,
                    children: viewResponders,
                    responder: hitTestingResponder
                )
            )
            
            output.viewResponders = filter
        }
        
        return output
    }
    
    private struct _AllowsHitTestingModifier_ChildEnvironment: Rule {
        
        internal typealias Value = EnvironmentValues
        
        @Attribute
        internal var modifier: _AllowsHitTestingModifier
        
        @Attribute
        internal var environment: EnvironmentValues
        
        internal var value: EnvironmentValues {
            var environmentValue = environment
            environmentValue[EnvironmentValues.AllowsHitTestingKey.self] = modifier.allowsHitTesting
            return environmentValue
        }
        
    }
}

@available(iOS 13.0, *)
fileprivate struct AllowsHitTestingFilter: StatefulRule { // $ae5344
    
    internal typealias Value = [ViewResponder]
    
    @Attribute
    internal var modifier: _AllowsHitTestingModifier
    
    @Attribute
    internal var children: [ViewResponder]
    
    internal let responder: AllowsHitTestingResponder
    
    internal mutating func updateValue() {
        responder._allowsHitTesting = modifier.allowsHitTesting
        
        let (childrenValue, changed) = $children.changedValue()
        if changed {
            responder.children = childrenValue
        }
        
        if !hasValue {
            value = [responder]
        }
    }
    
}

@available(iOS 13.0, *)
private final class AllowsHitTestingResponder: DefaultLayoutViewResponder { // $ae5260
    
    fileprivate var _allowsHitTesting: Bool
    
    fileprivate override var allowsHitTesting: Bool {
        _allowsHitTesting
    }
    
    fileprivate override init(inputs: _ViewInputs) {
        self._allowsHitTesting = true
        super.init(inputs: inputs)
    }
    
    fileprivate override func extendPrintTree(string: inout String) {
        string.append("allowed " + (allowsHitTesting ? "true" : "false"))
    }
    
    fileprivate override func containsGlobalPoints(_ globalPoints: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        guard allowsHitTesting else {
            return ContainsPointsResult()
        }
        
        return super.containsGlobalPoints(globalPoints, isDerived: isDerived, cacheKey: cacheKey)
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    fileprivate struct AllowsHitTestingKey: EnvironmentKey {
        
        @inline(__always)
        static var defaultValue: Bool { true }
        
        internal typealias Value = Bool
        
    }
}
