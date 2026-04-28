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
@_spi(DanceUI) import DanceUIObservation


@frozen
@available(iOS 13.0, *)
public struct _PreferenceReadingView<Key: PreferenceKey, Content: View>: UnaryView, PrimitiveView {
    
    public var value: _PreferenceValue<Key>
    
    public var transform: (Key.Value) -> Content
    
    @inlinable
    public init(value: _PreferenceValue<Key>, transform: @escaping (Key.Value) -> Content) {
        self.value = value
        self.transform = transform
    }
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        var childInputs = inputs
        
        let child = Attribute(PreferenceReadingChild<Key, Content>(view: view.value))
        child.flags = .removable
        
        childInputs.preferences.remove(Key.self)
        
        return Content.makeDebuggableView(value: _GraphValue(child), inputs: childInputs)
    }
}

@available(iOS 13.0, *)
private struct PreferenceReadingChild<Key: PreferenceKey, ViewType: View>: StatefulRule, ObservationAttribute {
    
    fileprivate typealias Value = ViewType
    
    @Attribute
    fileprivate var view: _PreferenceReadingView<Key, ViewType>

    fileprivate var previousObservationTrackings: [ObservationTracking]?

    fileprivate var deferredObservationGraphMutation: DeferredObservationGraphMutation?

    fileprivate mutating func updateValue() {
        let (view, isViewChanged) = $view.changedValue()
        value = withObservation(shouldCancelPrevious: isViewChanged) {
            view.transform(view.value.wrappedValue)
        }
    }
    
}
