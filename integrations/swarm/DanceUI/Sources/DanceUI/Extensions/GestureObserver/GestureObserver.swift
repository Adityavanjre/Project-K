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

/// A gesture observer accesses `UIGestureRecognizer` object with given key-path
/// on `GestureObservers`.
///
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@frozen
@propertyWrapper
@available(iOS 13.0, *)
public struct GestureObserver<
    GestureRecognizer: UIGestureRecognizer & AnyHostedGestureObserving
>: DynamicProperty {
    
    @frozen
    @usableFromInline
    internal enum Content {
        
        case keyPath(KeyPath<GestureObservers, GestureRecognizer?>)
        
        case value(GestureRecognizer?)
        
    }
    
    @usableFromInline
    internal var content: Content
    
    @inlinable
    public var wrappedValue: GestureRecognizer? {
        switch content {
        case .keyPath(let keypath):
            return GestureObservers()[keyPath: keypath]
        case .value(let value):
            return value
        }
    }
    
    @inlinable
    public var projectedValue: GestureObserver {
        self
    }
    
    @inlinable
    public init(_ keyPath: KeyPath<GestureObservers, GestureRecognizer?>) {
        content = .keyPath(keyPath)
    }
    
    @usableFromInline
    internal func error() -> Never {
        _danceuiFatalError("Reading GestureObserver<\(GestureRecognizer.self)>")
    }
    
    public static func _makeProperty<Container>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<Container>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        buffer.append(GestureRecognizerObserverBox<GestureRecognizer>(gestureRecognizerObservers: inputs.gestureObservers),
                      fieldOffset: fieldOffset)
    }
    
}

@available(iOS 13.0, *)
private struct GestureRecognizerObserverBox<ValueType: UIGestureRecognizer & AnyHostedGestureObserving>: DynamicPropertyBox {
    
    fileprivate typealias Property = GestureObserver<ValueType>
    
    @OptionalAttribute
    fileprivate var gestureRecognizerObservers: GestureObservers?
    
    fileprivate var keyPath: KeyPath<GestureObservers, ValueType?>?
    
    fileprivate var value: ValueType?
    
    fileprivate init(gestureRecognizerObservers: OptionalAttribute<GestureObservers>) {
        self._gestureRecognizerObservers = gestureRecognizerObservers
        self.keyPath = nil
        self.value = nil
    }
    
    fileprivate mutating func update(property: inout GestureObserver<ValueType>, phase: _GraphInputs.Phase) -> Bool {
        let (observers, isChanged) = $gestureRecognizerObservers?.changedValue() ?? (GestureObservers(), true)
        
        guard case .keyPath(let keyPath) = property.content else {
            return false
        }
        
        let isKeyPathChanged = keyPath != self.keyPath
        
        if isKeyPathChanged {
            self.keyPath = keyPath
        }
        
        var isValueChanged: Bool = false
        
        if isKeyPathChanged || isChanged {
            let newValue = observers[keyPath: keyPath]
            
            if let oldValue = self.value {
                if !DGCompareValues(lhs: oldValue, rhs: newValue) {
                    self.value = newValue
                    isValueChanged = true
                }
            } else {
                self.value = newValue
                isValueChanged = true
            }
        }
        
        property.content = .value(value)
        
        return isValueChanged
    }
    
}
