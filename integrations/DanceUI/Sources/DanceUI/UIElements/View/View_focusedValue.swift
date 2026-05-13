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

@available(iOS 13.0, *)
extension View {
    
    /// Modifies this view by injecting a value that you provide for use by
    /// other views whose state depends on the focused view hierarchy.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to associate `value` with when adding
    ///     it to the existing table of exported focus values.
    ///   - value: The focus value to export.
    /// - Returns: A modified representation of this view.
    public func focusedValue<Value>(_ keyPath: WritableKeyPath<FocusedValues, Value?>, _ value: Value) -> some View {
        modifier(ResponderViewModifier<FocusedValueModifier<Value?>> { responder in
            FocusedValueModifier<Value?>(keyPath: keyPath, value: value, responder: responder, isSceneValue: false)
        })
    }
    
    /// Creates a new view that exposes the provided value to other views whose
    /// state depends on the focused view hierarchy.
    ///
    /// Use this method instead of ``View/focusedSceneValue(_:_:)`` when your
    /// scene includes multiple focusable views with their own associated
    /// values, and you need an app- or scene-scoped element like a command or
    /// toolbar item that operates on the value associated with whichever view
    /// currently has focus. Each focusable view can supply its own value:
    ///
    ///
    ///
    /// - Parameters:
    ///   - keyPath: The key path to associate `value` with when adding
    ///     it to the existing table of exported focus values.
    ///   - value: The focus value to export, or `nil` if no value is
    ///     currently available.
    /// - Returns: A modified representation of this view.
    public func focusedValue<Value>(_ keyPath: WritableKeyPath<FocusedValues, Value?>, _ value: Value?) -> some View {
        modifier(ResponderViewModifier<FocusedValueModifier<Value?>> { responder in
            FocusedValueModifier<Value?>(keyPath: keyPath, value: value, responder: responder, isSceneValue: false)
        })
    }
    
}

@available(iOS 13.0, *)
internal struct FocusedValueModifier<A>: MultiViewModifier, PrimitiveViewModifier {
    
    internal let keyPath: WritableKeyPath<FocusedValues, A>
    
    internal let value: A
    
    internal let responder: ResponderNode
    
    internal var isSceneValue: Bool
    
    internal static func _makeView(modifier: _GraphValue<FocusedValueModifier<A>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var outputs = body(_Graph(), inputs)
        outputs.makePreferenceTransformer(inputs: inputs,
                                          key: FocusedValueList.Key.self,
                                          transform: Attribute(Transform(viewPhase: inputs.phase,
                                                                         modifier: modifier.value,
                                                                         focusItem: inputs.focusedItem.attribute!,
                                                                         updateSeed: ViewGraph.current.$updateSeed,
                                                                         resetSeed: nil,
                                                                         content: nil,
                                                                         isFocused: false,
                                                                         lastUpdateSeed: .max,
                                                                         ttl: 0)))
        return outputs
    }
    
    internal struct Transform<Content>: StatefulRule {
        
        internal typealias Value = (inout FocusedValueList) -> Void
        
        @Attribute
        internal var viewPhase: _GraphInputs.Phase
        
        @Attribute
        internal var modifier: FocusedValueModifier<Content>
        
        @Attribute
        internal var focusItem: FocusItem?
        
        @Attribute
        internal var updateSeed: UInt32
        
        internal var resetSeed: UInt32?
        
        internal var content: Content?

        internal var isFocused: Bool

        internal var lastUpdateSeed: UInt32

        internal var ttl: UInt32
        
        @inlinable
        internal init(viewPhase: Attribute<_GraphInputs.Phase>,
                      modifier: Attribute<FocusedValueModifier<Content>>,
                      focusItem: Attribute<FocusItem?>,
                      updateSeed: Attribute<UInt32>,
                      resetSeed: UInt32? = nil,
                      content: Content? = nil,
                      isFocused: Bool = false,
                      lastUpdateSeed: UInt32 = .max,
                      ttl: UInt32 = 0) {
            self._viewPhase = viewPhase
            self._modifier = modifier
            self._focusItem = focusItem
            self._updateSeed = updateSeed
            self.resetSeed = resetSeed
            self.content = content
            self.isFocused = isFocused
            self.lastUpdateSeed = lastUpdateSeed
            self.ttl = ttl
        }
        
        internal mutating func updateValue() {
            let (modifier, isModifierChanged) = $modifier.changedValue()
            
            let (focusItem, isFocusItemChanged) = $focusItem.changedValue()
            
            let viewPhase = self.viewPhase
            
            let resetSeed = self.resetSeed
            
            let noResetSeed = resetSeed == nil
            
            let phaseSeed = viewPhase.seed
            
            if phaseSeed != resetSeed {
                self.resetSeed = viewPhase.seed
                lastUpdateSeed = 0
                ttl = 0
            }
            
            let mismatchedResetSeed = phaseSeed != resetSeed
            
            guard shouldUpdate() else {
                return
            }
            
            let isContentUpdated = updateContent(data: (isModifierChanged, modifier))
            
            let needsSetValue = isContentUpdated ? true : noResetSeed || mismatchedResetSeed
            
            if isFocusItemChanged {
                let shouldFocus = focusItem?.responder?.isDescendant(of: modifier.responder) ?? false
                if shouldFocus != isFocused {
                    isFocused = shouldFocus
                } else if !noResetSeed && hasValue {
                    return
                }
            } else if !needsSetValue && hasValue {
                return
            }
            
            let isFocused = self.isFocused
            
            let item = FocusedValueList.Item(isFocused: isFocused) { values in
                values.storageOptions = FocusedValues.StorageOptions(isFocused: isFocused,
                                                                     isScene: modifier.isSceneValue)
                values[keyPath: modifier.keyPath] = modifier.value
            }
            
            value = { focusedValueList in
                focusedValueList.items.append(item)
            }
        }
        
        @inline(__always)
        private mutating func shouldUpdate() -> Bool {
            if updateSeed != lastUpdateSeed {
                lastUpdateSeed = updateSeed
                ttl = 2
            } else if ttl != 0 {
                ttl &-= 1
            } else if hasValue {
                return false
            }
            
            return true
        }
        
        @inline(__always)
        private mutating func updateContent(data: (isChanged: Bool, value: FocusedValueModifier<Content>)) -> Bool {
            let (isChanged, modifier) = data
            guard isChanged,
                  content.map({!DGCompareValues(lhs: $0, rhs: modifier.value)}) != false else {
                return false
            }
            
            self.content = modifier.value
            return true
        }
        
    }
}
