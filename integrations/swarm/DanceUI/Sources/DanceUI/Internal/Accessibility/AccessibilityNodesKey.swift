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
extension PreferencesInputs {
    
    @inlinable
    internal var requiresAccessibilityNodes: Bool {
        get {
            contains(AccessibilityNodesKey.self)
        }
        set {
            if newValue {
                add(AccessibilityNodesKey.self)
            } else {
                remove(AccessibilityNodesKey.self)
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension _ViewOutputs {
    
    internal var accessibilityNodes: Attribute<AccessibilityNodeList>? {
        get {
            self[AccessibilityNodesKey.self]
        }
        set {
            self[AccessibilityNodesKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
internal struct AccessibilityNodesKey: PreferenceKey {
    
    internal typealias Value = AccessibilityNodeList
    
    @inline(__always)
    internal static var defaultValue: AccessibilityNodeList { AccessibilityNodeList(nodes: [], version: .zero) }
    
    internal static func reduce(value: inout Value, nextValue: () -> Value) {
        let newValue = nextValue()
        value.nodes.append(contentsOf: newValue.nodes)
        value.version.max(rhs: newValue.version)
    }
    
}
