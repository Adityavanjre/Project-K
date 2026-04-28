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
internal struct TransformEvent: HitTestableEventType, SpatialEventType, Equatable {

    internal var timestamp: Time

    internal var phase: EventPhase

    internal var binding: EventBinding?

    internal var globalLocation: CGPoint

    internal var initialScale: CGFloat

    internal var scaleDelta: CGFloat

    internal var initialAngle: Angle

    internal var angleDelta: Angle
    
    internal var location: CGPoint {
        get {
            globalLocation
        }
        set {
            globalLocation = newValue
        }
    }
    
    @inlinable
    internal var radius: CGFloat {
        0.0
    }
    
}
