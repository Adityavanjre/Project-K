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

import Foundation

@available(iOS 13.0, *)
internal struct VelocitySampler<Value: VectorArithmetic> {

    internal var sample1: (Value, Time)?

    internal var sample2: (Value, Time)?

    internal var sample3: (Value, Time)?

    internal var lastTime: Time?

    internal let previousSampleWeight: Double
    
    internal mutating func addSample(_ value: Value, time: Time) {
        if let lastTime = lastTime, lastTime > time {
            print("InValid sample \(value) with time \(time) > last time \(lastTime)")
            return
        }
        
        let newSample = (value, time)
        
        if lastTime == time {
            if sample3 != nil {
                sample3 = newSample
            } else if sample2 != nil {
                sample2 = newSample
            } else {
                sample1 = newSample
            }
        } else {
            lastTime = time
            if sample3 != nil {
                sample1 = sample2
                sample2 = sample3
                sample3 = newSample
            } else if sample2 != nil {
                sample3 = newSample
            } else if sample1 != nil {
                sample2 = newSample
            } else {
                sample1 = newSample
            }
        }
        

    }
    
    internal var velocity: _Velocity<Value> {
        guard let sample1 = sample1, let sample2 = sample2 else {
            return .init(valuePerSecond: .zero)
        }
        
        var Δdisplacement01 = sample2.0 - sample1.0
        let Δtime01 = sample2.1 - sample1.1

        Δdisplacement01.scale(by: 1 / Δtime01.seconds)
        
        guard let sample3 = sample3 else {
            return .init(valuePerSecond: Δdisplacement01)
        }
        
        var Δdisplacement12 = sample3.0 - sample2.0
        let Δtime12 = sample3.1 - sample2.1
        
        Δdisplacement12.scale(by: 1 / Δtime12.seconds)
        
        var velocityDiff = (Δdisplacement12 - Δdisplacement01)
        velocityDiff.scale(by: previousSampleWeight)
        
        return _Velocity(valuePerSecond: Δdisplacement12 - velocityDiff)
    }

} 
