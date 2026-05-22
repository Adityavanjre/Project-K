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
internal struct TouchEvent: HitTestableEventType, PanEventType, SpatialEventType, Equatable {
    
    internal var timestamp: Time

    internal var phase: EventPhase

    internal var binding: EventBinding?

    internal var location: CGPoint

    internal var globalLocation: CGPoint

    internal var radius: CGFloat

    internal var force: Double

    internal var maximumPossibleForce: Double

    internal weak var platform: UITouch?
    
    internal init(timestamp: Time, phase: EventPhase, binding: EventBinding?, location: CGPoint, globalLocation: CGPoint, radius: CGFloat, force: Double, maximumPossibleForce: Double, platform: UITouch? = nil) {
        self.timestamp = timestamp
        self.phase = phase
        self.binding = binding
        self.location = location
        self.globalLocation = globalLocation
        self.radius = radius
        self.force = force
        self.maximumPossibleForce = maximumPossibleForce
        self.platform = platform
    }
    
    internal var globalTranslation : CGSize {
        CGSize(width: globalLocation.x, height: globalLocation.y)
    }
    
    internal var translation : CGSize {
        CGSize(width: location.x, height: location.y)
    }
    
}
