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

@frozen
@available(iOS 13.0, *)
public struct _ConditionalContent<TrueContent, FalseContent> {
    
    @usableFromInline
    internal
    let storage: Storage
    
    @usableFromInline
    @frozen
    internal enum Storage {
        case trueContent(TrueContent)
        case falseContent(FalseContent)
    }

}

@available(iOS 13.0, *)
extension _ConditionalContent: View, PrimitiveView where TrueContent: View, FalseContent: View {
    
    public typealias Body = Never
    
    @usableFromInline
    internal init(storage: Storage) {
        self.storage = storage
    }
    
    private struct ChildView: Rule {

        internal typealias Value = AnyView
        
        @Attribute
        internal var content: _ConditionalContent

        internal let ids: (UniqueID, UniqueID)
        
        internal init(content: Attribute<_ConditionalContent>) {
            self._content = content
            self.ids = (UniqueID(), UniqueID())
        }
        
        internal var value: Value {
            switch content.storage {
            case .trueContent(let view):
                return AnyView(view, id: ids.0)
            case .falseContent(let view):
                return AnyView(view, id: ids.1)
            }
        }

    }
    
    public static func _makeView(view: _GraphValue<_ConditionalContent<TrueContent, FalseContent>>, inputs: _ViewInputs) -> _ViewOutputs {
        makeImplicitRoot(view: view, inputs: inputs)
    }
    
    public static func _makeViewList(view: _GraphValue<_ConditionalContent<TrueContent, FalseContent>>, inputs: _ViewListInputs) -> _ViewListOutputs {
        
        let child = ChildView(content: view.value)
        return AnyView._makeViewList(view: _GraphValue(child), inputs: inputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        guard let trueViewListCount = TrueContent._viewListCount(inputs: inputs),
              let falseViewListCount = FalseContent._viewListCount(inputs: inputs),
              trueViewListCount == falseViewListCount else {
            return nil
        }
        
        return trueViewListCount
    }
    
}
