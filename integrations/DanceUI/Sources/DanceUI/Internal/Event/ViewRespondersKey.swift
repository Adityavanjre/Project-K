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
    internal var requiresViewResponders: Bool {
        get {
            contains(ViewRespondersKey.self)
        }
        set {
            if newValue {
                add(ViewRespondersKey.self)
            } else {
                remove(ViewRespondersKey.self)
            }
        }
    }

}

@available(iOS 13.0, *)
extension _ViewOutputs {
    
    internal var viewResponders: Attribute<[ViewResponder]>? {
        get {
            self[ViewRespondersKey.self]
        }
        set {
            self[ViewRespondersKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
internal struct ViewRespondersKey: PreferenceKey {
    
    internal static var defaultValue: [ViewResponder] { [] }
    
    internal static func reduce(value: inout [ViewResponder], nextValue: () -> [ViewResponder]) {
        value.append(contentsOf: nextValue())
    }
    
    internal static var _includesRemovedValues: Bool { return true }
    
    internal typealias Value = [ViewResponder]
    
}
