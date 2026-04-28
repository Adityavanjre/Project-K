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

@available(iOS 13.0, *)
internal struct DistanceGesture: Gesture {

    internal typealias Value = CGFloat

    internal var minimumDistance: CGFloat

    internal var maximumDistance: CGFloat
    
    var body: ModifierGesture<StateContainerGesture<StateType, SpatialEvent, CGFloat>, EventListener<SpatialEvent>> {
        let listener = EventListener<SpatialEvent>()
        let gesture = StateContainerGesture<StateType, SpatialEvent, CGFloat> { stateType, gesturePhase in
            
            let currentDistance: CGFloat?
            if let event = gesturePhase.unwrapped {
                if let start = stateType.start {
                    let distance = sqrt(pow((start.x - event.location.x), 2) + pow((start.y - event.location.y), 2))
                    stateType.maxDistance = max(distance, stateType.maxDistance)
                    currentDistance = distance
                } else {
                    stateType.start = event.location
                    currentDistance = 0
                }
            } else {
                currentDistance = nil
            }
            
            switch gesturePhase {
            case .possible:
                return .possible(currentDistance)
            case .active:
                if currentDistance! > maximumDistance {
                    return .failed
                }
                if stateType.maxDistance < minimumDistance {
                    return .possible(currentDistance)
                }
                return .active(currentDistance!)
            case .ended:
                if stateType.maxDistance < minimumDistance || currentDistance! > maximumDistance {
                    return .failed
                }
                return .ended(currentDistance!)
            case .failed:
                return .failed
            }
            
        }
        return listener.modifier(gesture)
    }
    
    internal struct StateType: GestureStateProtocol {

        internal var start: CGPoint?

        internal var maxDistance: CGFloat

        init() {
            self.start = nil
            self.maxDistance = 0
        }

    }

}
