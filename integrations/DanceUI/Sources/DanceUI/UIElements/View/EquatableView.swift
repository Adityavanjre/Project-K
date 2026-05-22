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
internal import DanceUIRuntime

/// A view type that compares itself against its previous value and prevents its
/// child updating if its new value is the same as its old value.
@frozen
@available(iOS 13.0, *)
public struct EquatableView<Content> : UnaryView, PrimitiveView where Content : Equatable, Content : View {
    
    public var content: Content
    
    @inlinable
    public init(content: Content) {
        self.content = content
    }
    
    fileprivate struct Child: Rule {
        
        internal typealias Value = Content
        
        @Attribute
        internal var view: EquatableView<Content>
        
        internal static var comparisonMode: DGComparisonMode {
            .equatable
        }
        
        internal var value: Value {
            view.content
        }
        
    }
    
    public static func _makeView(view: _GraphValue<Self>,
                                 inputs: _ViewInputs) -> _ViewOutputs {
        let child = Attribute(Child(view: view.value))
        return Content.makeDebuggableView(value: _GraphValue(child), inputs: inputs)
    }
    
}

@available(iOS 13.0, *)
extension View where Self : Equatable {
    
    /// Prevents the view from updating its child view when its new value is the
    /// same as its old value.
    @inlinable
    public func equatable() -> EquatableView<Self> {
        EquatableView(content: self)
    }
    
}
