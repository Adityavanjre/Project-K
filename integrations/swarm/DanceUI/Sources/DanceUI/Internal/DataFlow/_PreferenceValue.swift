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
extension _PreferenceValue {
    
    @inlinable
    public func _force<T: View>(_ transform: @escaping (Key.Value) -> T) -> _PreferenceReadingView<Key, T> {
        return _PreferenceReadingView(value: self, transform: transform)
    }
    
}

@available(iOS 13.0, *)
public struct _PreferenceValue<Key: PreferenceKey> {
    
    internal var attribute: WeakAttribute<Key.Value>

    internal var wrappedValue: Key.Value {
        attribute.value ?? Key.defaultValue
    }
    
}

@available(iOS 13.0, *)
internal struct PreferenceValueAttribute<Key: PreferenceKey>: Rule {
    
    internal typealias Value = Key.Value
    
    internal static var initialValue: Value? {
        Key.defaultValue
    }
    
    @WeakAttribute
    internal var source: Key.Value?
    
    internal var value: Value {
        source ?? Key.defaultValue
    }
    
    internal static func setSource(_ source: Attribute<Key.Value>?, of preferenceValueAttribute: Attribute<Key.Value>) {
        preferenceValueAttribute.mutateBody(as: PreferenceValueAttribute<Key>.self, invalidating: false) { body in
            body.$source = source
        }
    }

}
