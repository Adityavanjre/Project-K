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
internal struct ZipLocation<FirstValue, SecondValue>: Location {
    
    internal typealias Value = ZippedValue<FirstValue, SecondValue>
    
    private let locations: CompoundLocation2<FirstValue, SecondValue>
    
    internal init(_ firstLocation: AnyLocation<FirstValue>, _ secondLocation: AnyLocation<SecondValue>) {
        locations = CompoundLocation2(first: firstLocation, second: secondLocation)
    }
    
    internal var wasRead: Bool {
        get {
            locations.first.wasRead || locations.second.wasRead
        }
        set {
            locations.first.wasRead = newValue
            locations.second.wasRead = newValue
        }
    }
    
    internal func get() -> Value {
        Value(first: locations.first.get(), second: locations.second.get())
    }
    
    internal mutating func set(_ value: Value, transaction: Transaction) {
        locations.first.set(value.first, transaction: transaction)
        locations.second.set(value.second, transaction: transaction)
    }
    
    internal func update() -> (Value, Bool) {
        let (firstValue, isFirstChanged) = locations.first.update()
        let (secondValue, isSecondChanged) = locations.second.update()
        return (Value(first: firstValue, second: secondValue), isFirstChanged || isSecondChanged)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct CompoundLocation2<First, Second> {
    
    fileprivate var first: AnyLocation<First>
    
    fileprivate var second: AnyLocation<Second>
    
}

/// A performance optimized structure of tupled elements for lower version Swift
/// runtime.
@available(iOS 13.0, *)
internal struct ZippedValue<FirstValue, SecondValue> {
    
    internal var first: FirstValue
    
    internal var second: SecondValue
    
}
