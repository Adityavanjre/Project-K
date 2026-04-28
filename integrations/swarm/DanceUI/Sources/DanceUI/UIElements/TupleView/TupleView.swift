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

/// A View created from a swift tuple of View values.
@frozen
@available(iOS 13.0, *)
public struct TupleView<T> : View, PrimitiveView {
    
    public var value: T

    @inlinable
    public init(_ value: T) {
        self.value = value
    }
    
    public static func _makeView(view: _GraphValue<TupleView<T>>, inputs: _ViewInputs) -> _ViewOutputs {
        let contentTypes = ViewDescriptor.typeDescription(DGTupleType(T.self)).contentTypes
        
        if contentTypes.count == 0 {
            return _ViewOutputs()
        } else if contentTypes.count == 1 {
            
            var visitor = MakeUnary(view: view, inputs: inputs, outputs: nil)
            
            let (_, viewConformance) = contentTypes[0]
            
            viewConformance.visitType(visitor: &visitor)
            
            guard let outputs = visitor.outputs else {
                _danceuiPreconditionFailure()
            }
            return outputs
            
        } else {
            return makeImplicitRoot(view: view, inputs: inputs)
        }
    }
    
    public static func _makeViewList(view: _GraphValue<TupleView<T>>, inputs: _ViewListInputs) -> _ViewListOutputs {
        let tupleType = DGTupleType(T.self)
        let contentTypes = ViewDescriptor.typeDescription(tupleType).contentTypes
        var makeList = MakeList(
            view: view,
            inputs: inputs,
            index: 0,
            offset: 0,
            wrapChildren: inputs.tupleViewCreatesUnaryElements,
            outputs: []
        )
        if inputs.tupleViewCreatesUnaryElements,
           makeList.inputs.tupleViewCreatesUnaryElements {
            makeList.inputs.requiresSections = false
            makeList.inputs.tupleViewCreatesUnaryElements = false
        }
        
        // for performance
        makeList.outputs.reserveCapacity(contentTypes.count)
        
        for (index, conformance) in contentTypes {
            makeList.index = index
            makeList.offset = tupleType.offset(at: index)
            conformance.visitType(visitor: &makeList)
        }
        return _ViewListOutputs.concat(makeList.outputs, inputs: makeList.inputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        let contentTypes = ViewDescriptor.typeDescription(DGTupleType(T.self)).contentTypes
        guard !inputs.options.contains(.tupleViewCreatesUnaryElements) else {
            return contentTypes.count
        }
        
        guard !contentTypes.isEmpty else {
            return 0
        }
        
        var visitor = CountViews(inputs: inputs)
        contentTypes.forEach { (_, type) in
            type.visitType(visitor: &visitor)
        }
        
        return visitor.result
    }
    
    private struct CountViews: ViewTypeVisitor {
        fileprivate var inputs: _ViewListCountInputs

        fileprivate var result: Int? = 0
        
        fileprivate mutating func visit<ViewType: View>(type: ViewType.Type) {
            guard let currentViewCount = result else {
                return
            }
            guard let viewCount = type._viewListCount(inputs: self.inputs) else {
                result = nil
                return
            }
            result = currentViewCount &+ viewCount
        }
    }
    
    internal struct MakeUnary: ViewTypeVisitor {
        
        internal var view: _GraphValue<TupleView<T>>

        internal var inputs: _ViewInputs

        internal var outputs: _ViewOutputs?
        
        internal mutating func visit<A1: View>(type: A1.Type) {
            let viewAsType = view.unsafeBitCast(to: type)
            
            outputs = type.makeDebuggableView(value: viewAsType, inputs: inputs)
        }
        
    }
    
    private struct MakeList: ViewTypeVisitor {
        
        internal var view: _GraphValue<TupleView<T>>
        
        internal var inputs: _ViewListInputs
        
        internal var index: Int
        
        internal var offset: Int
        
        internal let wrapChildren: Bool
        
        internal var outputs: [_ViewListOutputs]
        
        internal mutating func visit<V>(type: V.Type) where V : View {
            let view = view.value.unsafeOffset(at: offset, as: V.self)
            let output = if wrapChildren {
                _ViewListOutputs.unaryViewList(view: _GraphValue(view), inputs: inputs)
            } else {
                V.makeDebuggableViewList(value: _GraphValue(view), inputs: inputs)
            }
            outputs.append(output)
            inputs.implicitID = output.nextImplicitID
        }
    }
}
