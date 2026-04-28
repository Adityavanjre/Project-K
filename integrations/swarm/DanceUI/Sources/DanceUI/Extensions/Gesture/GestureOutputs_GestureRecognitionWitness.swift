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
extension _GestureOutputs {
    
    /// Makes a default terminal gesture outputs.
    ///
    /// - Note: Some gesture inputs are returned to the outputs at the terminal
    /// of gesture tree.
    ///
    @inline(__always)
    internal static func makeDefault(viewGraph: ViewGraph, inputs: _GestureInputs) -> _GestureOutputs where A == Void {
        makeTerminal(from: inputs, with: viewGraph.$failedPhase, viewGraph: viewGraph)
    }
    
    /// Makes a terminal gesture outputs.
    ///
    /// - Note: Some gesture inputs are returned to the outputs at the terminal
    /// of gesture tree.
    ///
    @inline(__always)
    internal static func makeTerminal(from inputs: _GestureInputs, with phase: Attribute<GesturePhase<A>>, viewGraph: ViewGraph = .current) -> _GestureOutputs {
        .make(phase: phase)
    }
    
    /// Makes an `_GestureOutputs` that just unconditionally merges optional
    /// outputs in `outputs1` and `outputs2`.
    ///
    @inline(__always)
    internal static func makeMerged<T1, T2>(phase: Attribute<GesturePhase<A>>,
                                            inputs: _GestureInputs,
                                            outputs1: _GestureOutputs<T1>,
                                            outputs2: _GestureOutputs<T2>) -> _GestureOutputs {
        @inline(__always)
        func merged<Value>(
            keyPath1: KeyPath<_GestureOutputs<T1>, Attribute<Value>?>,
            keyPath2: KeyPath<_GestureOutputs<T2>, Attribute<Value>?>,
            mergeValue: @escaping (Value, Value) -> Value
        ) -> Attribute<Value>? {
            let result: Attribute<Value>?
            let attr1 = outputs1[keyPath: keyPath1]
            let attr2 = outputs2[keyPath: keyPath2]
            switch (attr1, attr2) {
            case (.some(let lhs), .some(let rhs)):
                result = Attribute(MergedGestureOutput(data1: lhs, data2: rhs, mergeValue: mergeValue))
            case (.some(let lhs), .none):
                result = lhs
            case (.none, .some(let rhs)):
                result = rhs
            case (.none, .none):
                result = nil
            }
            
            return result
        }
        
        var base = _GestureOutputs.make(phase: phase)
        
        if inputs.requiresGestureRecognitionWitness {
            let attribute = merged(
                keyPath1: \.gestureRecognitionWitness,
                keyPath2: \.gestureRecognitionWitness,
                mergeValue: {$0.merged(with: $1)}
            )
            
            base = base.withGestureRecognitionWitness(attribute)
        }
        
        if inputs.requiresPlatformGestureRecognizerList {
            let attribute = merged(
                keyPath1: \.platformGestureRecognizerList,
                keyPath2: \.platformGestureRecognizerList,
                mergeValue: {$0.appending($1)}
            )
            base = base.withPlatformGestureRecognizerList(attribute)
        }
        
        if inputs.requiresActiveGestureRecognizerObservers {
            let attribute = merged(
                keyPath1: \.activeGestureRecognizerObservers,
                keyPath2: \.activeGestureRecognizerObservers,
                mergeValue: {$0 + $1}
            )
            
            base = base.withActiveGestureRecognizerObservers(attribute)
        }
        
        return base
    }
    
    /// Makes an `_GestureOutputs` that:
    ///     - Concatenates gesture observation info of `makeOutputs1` to
    ///     `_GestureInputs` of `makeOutputs2` then direct to the final outputs.
    ///     - Filters gesture recognition witness and platform gesture
    ///     recognizer list of `makeOutputs1` and `makeOutputs1` which depends
    ///     on DanceUI's internal interpretation of given `style`.
    ///
    @inline(__always)
    internal static func makeBinaryFiltered<Parent: Gesture, PhaseValue1, PhaseValue2>(
        style: GestureOutputsBinaryFilterStyle,
        parent: _GraphValue<Parent>,
        inputs: _GestureInputs,
        makeOutputs1: (_GraphValue<Parent>, inout _GestureInputs) -> _GestureOutputs<PhaseValue1>,
        makeOutputs2: (_GraphValue<Parent>, inout _GestureInputs) -> _GestureOutputs<PhaseValue2>,
        makePhase: (_ outputs1: _GestureOutputs<PhaseValue1>, _ outputs2: _GestureOutputs<PhaseValue2>, _ inputs: _GestureInputs, _ inputs1: _GestureInputs, _ inputs2: _GestureInputs) -> Attribute<GesturePhase<A>>
    ) -> _GestureOutputs {
        var inputs1 = inputs
        let outputs1 = makeOutputs1(parent, &inputs1)
        var inputs2 = inputs1
        let outputs2 = makeOutputs2(parent, &inputs2)
        let phase = makePhase(outputs1, outputs2, inputs, inputs1, inputs2)
        
        @inline(__always)
        func makeBinaryPhaseDependent<Value>(
            keyPath1: KeyPath<_GestureOutputs<PhaseValue1>, Attribute<Value>?>,
            keyPath2: KeyPath<_GestureOutputs<PhaseValue2>, Attribute<Value>?>,
            mergeValue: @escaping (Value?, Value?) -> Value?,
            defaultValue: @escaping () -> Value
        ) -> Attribute<Value>? {
            let lhs = outputs1[keyPath: keyPath1]
            let rhs = outputs2[keyPath: keyPath2]
            guard lhs != nil || rhs != nil else {
                return nil
            }
            
            return Attribute(
                BinaryPhaseDependentGestureOutputFilter(
                    phase1: outputs1.phase,
                    phase2: outputs2.phase,
                    data1: OptionalAttribute(outputs1[keyPath: keyPath1]),
                    data2: OptionalAttribute(outputs2[keyPath: keyPath2]),
                    style: style,
                    mergeValue: mergeValue,
                    defaultValue: defaultValue
                )
            )
        }
        
        var base = _GestureOutputs.make(phase: phase)
        
        if inputs.requiresGestureRecognitionWitness {
            let attribute = makeBinaryPhaseDependent(
                keyPath1: \.gestureRecognitionWitness,
                keyPath2: \.gestureRecognitionWitness,
                mergeValue: { $0.merged(with: $1) },
                defaultValue: { GestureRecognitionWitness() }
            )
            base = base.withGestureRecognitionWitness(attribute)
        }
        
        if inputs.requiresPlatformGestureRecognizerList {
            let attribute = makeBinaryPhaseDependent(
                keyPath1: \.platformGestureRecognizerList,
                keyPath2: \.platformGestureRecognizerList,
                mergeValue: { $0.appending($1) },
                defaultValue: { PlatformGestureRecognizerList() }
            )
            base = base.withPlatformGestureRecognizerList(attribute)
        }
        
        if inputs.requiresActiveGestureRecognizerObservers {
            let attribute = makeBinaryPhaseDependent(
                keyPath1: \.activeGestureRecognizerObservers,
                keyPath2: \.activeGestureRecognizerObservers,
                mergeValue: { $0 + $1 },
                defaultValue: { [] }
            )
            base = base.withActiveGestureRecognizerObservers(attribute)
        }
        
        return base
    }
    

    internal func unsafeCast<T>(to type: T.Type) -> _GestureOutputs<T> {
        withPhase(phase.unsafeCast(to: GesturePhase<T>.self))
    }
    
}

@available(iOS 13.0, *)
internal enum GestureOutputsBinaryFilterStyle {
    
    case exclusive
    
    case simultaneous
    
    case sequenced
    
    case then
    
}

@available(iOS 13.0, *)
internal struct BinaryPhaseDependentGestureOutputFilter<T1, T2, Value>: Rule {
    
    @Attribute
    fileprivate var phase1: GesturePhase<T1>
    
    @Attribute
    fileprivate var phase2: GesturePhase<T2>
    
    @OptionalAttribute
    fileprivate var data1: Value?
    
    @OptionalAttribute
    fileprivate var data2: Value?
    
    fileprivate var style: GestureOutputsBinaryFilterStyle
    
    fileprivate var mergeValue: (Value?, Value?) -> Value?
    
    fileprivate var defaultValue: () -> Value
    
    internal init(
        phase1: Attribute<GesturePhase<T1>>,
        phase2: Attribute<GesturePhase<T2>>,
        data1: OptionalAttribute<Value>,
        data2: OptionalAttribute<Value>,
        style: GestureOutputsBinaryFilterStyle,
        mergeValue: @escaping (Value?, Value?) -> Value?,
        defaultValue: @escaping () -> Value
    ) {
        self._phase1 = phase1
        self._phase2 = phase2
        self._data1 = data1
        self._data2 = data2
        self.style = style
        self.mergeValue = mergeValue
        self.defaultValue = defaultValue
    }
    
    internal var value: Value {
        switch style {
        case .exclusive:
            return exclusive
        case .sequenced:
            return sequenced
        case .simultaneous:
            return simultaneous
        case .then:
            return then
        }
    }
    
    @inline(__always)
    private var exclusive: Value {
        let data: Value?
        
        switch (phase1, phase2) {
        case (.possible, .possible):
            data = mergeValue(data1, data2)
        case (.possible, .active):
            data = data2
        case (.possible, .ended):
            data = data2
        case (.possible, .failed):
            data = data1
        case (.active, _):
            data = data1
        case (.ended, _):
            data = data1
        case (.failed, .failed):
            data = nil
        case (.failed, _):
            data = data2
        }
        
        return data ?? defaultValue()
    }
    
    @inline(__always)
    private var sequenced: Value {
        let data: Value?
        switch phase1 {
        case .possible:
            data = data1
        case .active:
            data = data1
        case .ended:
            // First Gesture End, Second Gesture Begin
            switch phase2 {
            case .possible:
                data = data2
            case .active:
                data = data2
            case .ended:
                data = data2
            case .failed:
                data = nil
            }
        case .failed:
            data = nil
        }
        
        return data ?? defaultValue()
    }
    
    @inline(__always)
    private var simultaneous: Value {
        let data: Value?
        
        switch (phase1, phase2) {
        case (.failed, .failed):
            data = defaultValue()
        case (.failed, _):
            data = data2 ?? defaultValue()
        case (_, .failed):
            data = data1 ?? defaultValue()
        default:
            data = mergeValue(data1, data2)
        }
        
        return data ?? defaultValue()
    }
    
    @inline(__always)
    private var then: Value {
        let data: Value?
        
        switch (phase1, phase2) {
        case (.possible(_), _):
            data = mergeValue(data1, data2)
        case (.active, .possible):
            data = data1
        case (.active, _):
            data = mergeValue(data1, data2)
        case (.ended, .possible):
            data = data1
        case (.ended, _):
            data = mergeValue(data1, data2)
        case (.failed, _):
            data = defaultValue()
        }
        
        return data ?? defaultValue()
    }
    
}

@available(iOS 13.0, *)
private struct MergedGestureOutput<Value>: Rule {
    
    @Attribute
    fileprivate var data1: Value
    
    @Attribute
    fileprivate var data2: Value
    
    fileprivate var mergeValue: (Value, Value) -> Value
    
    fileprivate var value: Value {
        mergeValue(data1, data2)
    }
    
}

@available(iOS 13.0, *)
internal struct PairwisePreferenceCombinerVisitor_FeatureGestureContainer: PreferenceKeyVisitor {
    

    internal var outputs: (PreferencesOutputs, PreferencesOutputs)
    

    internal var result: PreferencesOutputs
    
    @inline(__always)
    internal mutating func visit<Key>(key: Key.Type) where Key : PreferenceKey {
        
        let value0 = outputs.0[key]
        let value1 = outputs.1[key]
        
        guard value0 != nil || value1 != nil else {
            return
        }
        
        if let firstValue = value0, let secondValue = value1 {
            result[key] = .init(PairPreferenceCombiner<Key>(attributes: (firstValue, secondValue)))
        } else {
            result[key] = value0 ?? value1
        }
    }
    
}
