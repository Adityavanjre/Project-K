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
internal protocol StyleContext {
   
}

@available(iOS 13.0, *)
internal struct StyleContextPredicate<A: StyleContext>: ViewInputPredicate {
    
    internal static func evaluate(inputs: _GraphInputs) -> Bool {
        inputs.styleContextType == AnyStyleContextType(base: StyleContextTypeBox<A>.self)
    }
}

@available(iOS 13.0, *)
internal struct NoStyleContext: StyleContext {
    
}

@available(iOS 13.0, *)
internal struct StyleContextInput: PropertyKey, ViewInput {
    internal typealias Value = AnyStyleContextType
    
    internal static var defaultValue: Value {
        AnyStyleContextType(base: StyleContextTypeBox<NoStyleContext>.self)
    }
}

@available(iOS 13.0, *)
internal protocol AnyStyleContextTypeBox {
    static func isEqual(to: AnyStyleContextTypeBox.Type) -> Bool
}

@available(iOS 13.0, *)
internal struct StyleContextTypeBox<A: StyleContext>: AnyStyleContextTypeBox {
    
    internal static func isEqual(to boxType: AnyStyleContextTypeBox.Type) -> Bool {
        boxType == StyleContextTypeBox<A>.self
    }
    
}

@available(iOS 13.0, *)
internal struct AnyStyleContextType: Equatable {

    internal let base: AnyStyleContextTypeBox.Type
    
    internal static func == (lhs: AnyStyleContextType, rhs: AnyStyleContextType) -> Bool {
        lhs.base.isEqual(to: rhs.base)
    }

}

@available(iOS 13.0, *)
internal struct ContentListStyleContext: StyleContext {

}

@available(iOS 13.0, *)
internal struct SidebarStyleContext: StyleContext {

}
