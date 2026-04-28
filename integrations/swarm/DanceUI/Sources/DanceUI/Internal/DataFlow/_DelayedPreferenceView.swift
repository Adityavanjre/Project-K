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

@available(iOS 13.0, *)
extension View {
    
    /// Reads the specified preference value from the view, using it to
    /// produce a second view that is applied as an overlay to the
    /// original view.
    ///
    /// The values of the preference key from both views
    /// are combined and made visible to the parent view.
    ///
    /// - Parameters:
    ///   - key: The preference key type whose value is to be read.
    ///   - alignment: An optional alignment to use when positioning the
    ///     overlay view relative to the original view.
    ///   - transform: A function that produces the overlay view from
    ///     the preference value read from the original view.
    ///
    /// - Returns: A view that layers a second view in front of the view.
    @inlinable
    public func overlayPreferenceValue<Key: PreferenceKey, T: View>(_ key: Key.Type = Key.self, @ViewBuilder _ transform: @escaping (Key.Value) -> T) -> some View {
        Key._delay {
            self.overlay($0._force(transform))
        }
    }
    
    /// Reads the specified preference value from the view, using it to
    /// produce a second view that is applied as the background of the
    /// original view.
    ///
    /// The values of the preference key from both views
    /// are combined and made visible to the parent view.
    ///
    /// - Parameters:
    ///   - key: The preference key type whose value is to be read.
    ///   - alignment: An optional alignment to use when positioning the
    ///     background view relative to the original view.
    ///   - transform: A function that produces the background view from
    ///     the preference value read from the original view.
    ///
    /// - Returns: A view that layers a second view behind the view.
    @inlinable
    public func backgroundPreferenceValue<Key: PreferenceKey, T: View>(_ key: Key.Type = Key.self, @ViewBuilder _ transform: @escaping (Key.Value) -> T) -> some View {
        Key._delay {
            self.background($0._force(transform))
        }
    }
    
}

@available(iOS 13.0, *)
extension PreferenceKey {
    
    @inlinable
    public static func _delay<T: View>(_ transform: @escaping (_PreferenceValue<Self>) -> T) -> some View {
        _DelayedPreferenceView(transform: transform)
    }
    
}


@frozen
@available(iOS 13.0, *)
public struct _DelayedPreferenceView<Key: PreferenceKey, Content: View>: UnaryView, PrimitiveView {
    
    public var transform: (_PreferenceValue<Key>) -> Content
    
    @inlinable
    public init(transform: @escaping (_PreferenceValue<Key>) -> Content) {
        self.transform = transform
    }
    
    public static func _makeView(view: _GraphValue<_DelayedPreferenceView<Key, Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        var childInputs = inputs
        
        let source = Attribute(PreferenceValueAttribute<Key>())
        
        let child = Attribute(DelayedPreferenceChild(view: view.value, source: source))
        
        child.flags = .removable
        
        childInputs.preferences.add(Key.self)
        
        let outputs = Content.makeDebuggableView(value: _GraphValue(child), inputs: childInputs)
        
        PreferenceValueAttribute<Key>.setSource(outputs[Key.self], of: source)
        
        return outputs
    }
    
}

@available(iOS 13.0, *)
private struct DelayedPreferenceChild<Key: PreferenceKey, ViewType: View>: StatefulRule, ObservationAttribute {
    
    fileprivate typealias Value = ViewType
    
    @Attribute
    fileprivate var view: _DelayedPreferenceView<Key, ViewType>
    
    @Attribute
    fileprivate var source: Key.Value

    fileprivate var previousObservationTrackings: [ObservationTracking]?

    fileprivate var deferredObservationGraphMutation: DeferredObservationGraphMutation?

    fileprivate mutating func updateValue() {
        let (view, isViewChanged) = $view.changedValue()
        let sourceAttribute = WeakAttribute($source)
        value = withObservation(shouldCancelPrevious: isViewChanged) {
            view.transform(_PreferenceValue(attribute: sourceAttribute))
        }
    }
    
}

