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

internal typealias PlatformGestureRecognizer = UIGestureRecognizer
@available(iOS 13.0, *)
internal struct PlatformGestureRecognizerList: CustomStringConvertible {
    
    private var gestureRecognizerForIDs: [ObjectIdentifier : Set<GestureID>]
    
    internal mutating func append(_ gestureRecognizer: PlatformGestureRecognizer, for ids: Set<GestureID>) {
        append(ObjectIdentifier(gestureRecognizer), for: ids)
    }
    
    private mutating func append(_ key: ObjectIdentifier, for ids: Set<GestureID>) {
        gestureRecognizerForIDs[key] = ids
    }
    
    internal func ids(for gestureRecognizer: PlatformGestureRecognizer) -> Set<GestureID>? {
        gestureRecognizerForIDs[ObjectIdentifier(gestureRecognizer)]
    }
    
    @inlinable
    internal init() {
        gestureRecognizerForIDs = Dictionary()
    }
    
    @inlinable
    internal mutating func append(_ another: PlatformGestureRecognizerList) {
        for (gestureRecognizer, idSet) in another.gestureRecognizerForIDs {
            append(gestureRecognizer, for: idSet)
        }
    }
    
    @inlinable
    internal func appending(_ another: PlatformGestureRecognizerList) -> PlatformGestureRecognizerList {
        var copied = self
        copied.append(another)
        return copied
    }
    
    @inlinable
    internal func appending(_ gestureRecognizer: UIGestureRecognizer, for ids: Set<GestureID>) -> PlatformGestureRecognizerList {
        var copied = self
        copied.append(gestureRecognizer, for: ids)
        return copied
    }
    
    internal var description: String {
        var components = [String]()
        components.append("<\(Self.self)>:")
        components.append("\n\tGestureRecognizer for IDs:")
        for (key, value) in gestureRecognizerForIDs {
            components.append("\n\t\t\(key) : \(value)")
        }
        return components.joined()
    }
    
    internal struct Key: PreferenceKey {
        
        internal typealias Value = PlatformGestureRecognizerList
        
        internal static func reduce(value: inout Value, nextValue: () -> Value) {
            var newValue = nextValue()
            newValue.append(value)
            value = newValue
        }
        
        internal static var defaultValue: Value {
            PlatformGestureRecognizerList()
        }
        
    }
    
}

@available(iOS 13.0, *)
extension PlatformGestureRecognizerList: Defaultable {
    
    internal typealias Value = PlatformGestureRecognizerList
    
    internal static var defaultValue: Value {
        Value()
    }
    
}

@available(iOS 13.0, *)
extension Optional where Wrapped == PlatformGestureRecognizerList {
    
    internal func appending(_ another: PlatformGestureRecognizerList?) -> PlatformGestureRecognizerList? {
        switch (self, another) {
        case (.some(let lhs), .none):
            return lhs
        case (.none, .some(let rhs)):
            return rhs
        case (.some(let lhs), .some(let rhs)):
            return lhs.appending(rhs)
        case (.none, .none):
            return nil
        }
    }
    
}

@available(iOS 13.0, *)
extension PreferencesInputs {
    
    @inlinable
    internal var requiresPlatformGestureRecognizerList: Bool {
        get {
            contains(PlatformGestureRecognizerList.Key.self)
        }
        set {
            if newValue {
                add(PlatformGestureRecognizerList.Key.self)
            } else {
                remove(PlatformGestureRecognizerList.Key.self)
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension _ViewOutputs {
    
    @inline(__always)
    internal var gestureRecognizerList: Attribute<PlatformGestureRecognizerList>? {
        get {
            self[PlatformGestureRecognizerList.Key.self]
        }
        
        set {
            self[PlatformGestureRecognizerList.Key.self] = newValue
        }
    }
    
}
