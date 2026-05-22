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

@available(iOS 13.0, *)
public struct _ViewListCountInputs {

    internal var customInputs: PropertyList

    internal var options: _ViewListInputs.Options

    internal var baseOptions: _GraphInputs.Options

    internal var customModifierTypes: [ObjectIdentifier]

    internal var base: _GraphInputs {
        var inputs = _GraphInputs.invalid
        inputs.customInputs = customInputs
        inputs.options = baseOptions
        return inputs
    }

    internal subscript<Input: GraphInput>(_ type: Input.Type) -> Input.Value {
        get {
            customInputs[type]
        }
        set {
            customInputs[type] = newValue
        }
    }

    internal mutating func popLast<A, B>(type: A.Type) -> B? where A: GraphInput, A.Value == Stack<B> {
        var currentValue = self[type]
        let returnValue = currentValue.pop()
        self[type] = currentValue
        return returnValue
    }

    internal mutating func append<A, B>(value: B, to type: A.Type) where A: GraphInput, A.Value == Stack<B> {
        var currentValue = self[type]
        currentValue.push(value)
        self[type] = currentValue
    }
}

@available(iOS 13.0, *)
internal struct BodyCountInput: ViewInput {
    internal typealias StackElement = (_ViewListCountInputs) -> Int?
    internal typealias Value = Stack<StackElement>
    internal static var defaultValue: Stack<StackElement> {
        .init()
    }
}
