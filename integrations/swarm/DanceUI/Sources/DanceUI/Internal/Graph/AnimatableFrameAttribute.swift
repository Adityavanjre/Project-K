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
internal struct AnimatableFrameAttribute: StatefulRule, ObservedAttribute {

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var size: ViewSize

    @Attribute
    internal var pixelLength: CGFloat

    @Attribute
    internal var environment: EnvironmentValues
    
    internal var helper: AnimatableAttributeHelper<ViewFrame>
    
    internal let animationsDisabled: Bool
    
    internal init(position: Attribute<ViewOrigin>,
                  size: Attribute<ViewSize>,
                  pixelLength: Attribute<CGFloat>,
                  environment: Attribute<EnvironmentValues>,
                  phase: Attribute<_GraphInputs.Phase>,
                  time: Attribute<Time>,
                  transaction: Attribute<Transaction>,
                  animationsDisabled: Bool) {
        _position = position
        _size = size
        _pixelLength = pixelLength
        _environment = environment
        helper = AnimatableAttributeHelper(phase: phase, time: time, transaction: transaction)
        self.animationsDisabled = animationsDisabled
    }
    
    internal mutating func destroy() {
        helper.removeListeners()
    }
    
}

@available(iOS 13.0, *)
extension AnimatableFrameAttribute {
    
    internal typealias Value = ViewFrame
    
    internal static let initialValue: ViewFrame? = .zero
    
    internal mutating func updateValue() {
        let (position, positionChanged) = _position.changedValue()
        let (size, sizeChanged) = _size.changedValue()
        let (pixelLength, pixelLengthChanged) = _pixelLength.changedValue()
        var anyChanged = positionChanged || sizeChanged || pixelLengthChanged
        
        var rect = CGRect(origin: position.value, size: size.value)
        rect.roundCoordinatesToNearestOrUp(toMultipleOf: pixelLength)
        var viewFrame = ViewFrame(origin: ViewOrigin(value: rect.origin),
                                  size: ViewSize(value: rect.size, _proposal: size._proposal))
        if !animationsDisabled {
            _updateViewFrame(value: &viewFrame,
                             changed: &anyChanged,
                             environment: _environment)
        }
        
        if anyChanged || !self.hasValue {
            self.value = viewFrame
        }
    }
    
    @inline(__always)
    private mutating func _updateViewFrame(value: inout ViewFrame,
                                           changed: inout Bool,
                                           environment: Attribute<EnvironmentValues>) {
        var param: (value: ViewFrame, changed: Bool) = (value, changed)
        helper.update(value: &param, environment: environment)
        value = param.value
        changed = param.changed
    }
}

@available(iOS 13.0, *)
internal struct AnimatableAttributeHelper<A: Animatable> {

    @Attribute
    internal var phase: _GraphInputs.Phase

    @Attribute
    internal var time: Time

    @Attribute
    internal var transaction: Transaction
    
    internal var previousModelData: A.AnimatableData? = nil
    
    internal var animatorState: AnimatorState<A.AnimatableData>? = nil
    
    internal var resetSeed: UInt32 = 0
    
    internal init(phase: Attribute<_GraphInputs.Phase>,
                  time: Attribute<Time>,
                  transaction: Attribute<Transaction>) {
        _phase = phase
        _time = time
        _transaction = transaction
    }
    
    internal mutating func reset() {
        let seed = self.phase.seed
        removeListeners()
        animatorState = nil
        previousModelData = nil
        resetSeed = seed
    }
    
    internal mutating func update(value: inout (value: A, changed: Bool),
                                  environment: Attribute<EnvironmentValues>) {
        var animationTime = self.animationTime
        
        if checkReset() {
            value.changed = true
        }
        
        updateAnimatorStateIfNeeded(value, 
                                    time: &animationTime,
                                    environment: environment)
        
        interpolateAnimatedValueIfNeeded(&value,
                                         animationTime: animationTime,
                                         environment: environment)
    }
    
    internal mutating func removeListeners() {
        guard let state = animatorState else {
            return
        }
        state.removeListeners()
    }
    
    @inline(__always)
    private var animationTime: Time {
        if animatorState == nil {
            return .never
        } else {
            let (time, isTimeChanged) = $time.changedValue()
            return isTimeChanged ? time : .never
        }
    }
    
    internal mutating func checkReset() -> Bool {
        guard self.phase.seed != self.resetSeed else {
            return false
        }
        reset()
        return true
    }
    
    @inline(__always)
    private mutating func updateAnimatorStateIfNeeded(_ value: (value: A, changed: Bool),
                                                      time: inout Time,
                                                      environment: Attribute<EnvironmentValues>) {
        guard value.changed && !_disableAnimations else {
            return
        }
        
        let modelData = value.value.animatableData
        
        defer {
            self.previousModelData = modelData
        }
        
        guard let previousModelData = previousModelData, modelData != previousModelData else {
            return
        }
        
        let transaction = DGGraphRef.withoutUpdate {
            self.transaction
        }
        
        guard let animation = transaction.animation, !transaction.disablesAnimations else {
            return
        }
          
        var interval = modelData
        interval -= previousModelData
        time = self.time
        if let animatorState = animatorState {
            animatorState.combine(newAnimaition: animation,
                                  newInterval: interval,
                                  at: time, in: transaction,
                                  environment: environment)
            self.animatorState = animatorState
        } else {
            self.animatorState = AnimatorState(animation: animation,
                                               interval: interval,
                                               at: time,
                                               in: transaction)
        }
        
        animatorState?.addListeners(transaction)
    }
    
    @inline(__always)
    private mutating func interpolateAnimatedValueIfNeeded(_ value: inout (value: A, changed: Bool),
                                                           animationTime: Time,
                                                           environment: Attribute<EnvironmentValues>) {
        guard let animatorState = animatorState else {
            return
        }
        
        if animatorState.update(&value.value.animatableData,
                                at: animationTime,
                                environment: environment) {
            self.removeListeners()
            self.animatorState = nil
        } else {
            ViewGraph.current.scheduleNextViewUpdate(byTime: animatorState.nextTime)
        }
        
        value.changed = true
    }
    
}

@available(iOS 13.0, *)
internal var _disableAnimations: Bool = false
