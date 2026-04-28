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
public struct _ResolvedKeyframeTrackContent<Value: Animatable> {
    
    internal var segments: [_ResolvedKeyframeTrackContent<Value>.Segment]
    
    internal enum Segment {
        
        case move(Value.AnimatableData)
        
        case cubic(Cubic)
        
        case spring(Spring)
        
        case linear(Linear)
        
        internal var end: Value.AnimatableData {
            switch self {
            case .move(let animatableData):
                return animatableData
            case .cubic(let cubic):
                return cubic.to
            case .spring(let spring):
                return spring.to
            case .linear(let linear):
                return linear.to
            }
        }
        
        
    }
    
    internal struct Cubic {

        internal var to: Value.AnimatableData

        internal var startVelocity: Value.AnimatableData?

        internal var endVelocity: Value.AnimatableData?

        internal var duration: Double


    }

    internal struct Spring {

        internal var to: Value.AnimatableData

        internal var spring: DanceUI.Spring

        internal var startVelocity: Value.AnimatableData?

        internal var duration: Double?


    }

    internal struct Linear {

        internal var to: Value.AnimatableData

        internal var duration: Double

        internal var timingCurve: UnitCurve
    }
}
