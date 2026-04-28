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
internal struct TappableSpatialEvent: EventType {
    
    internal var phase : EventPhase

    internal var timestamp : Time

    internal var binding : EventBinding?

    internal var globalLocation : CGPoint

    internal var location : CGPoint

    internal var radius : CGFloat
    
    internal init?(_ event: EventType) {
        guard let spatialEvent = event as? SpatialEventType else {
            return nil
        }
        self.init(
            phase: spatialEvent.phase,
            timestamp: spatialEvent.timestamp,
            binding: event.binding,
            globalLocation: spatialEvent.globalLocation,
            location: spatialEvent.location,
            radius: spatialEvent.radius
        )
    }
    
    @inlinable
    internal init(
        phase: EventPhase,
        timestamp: Time,
        binding: EventBinding?,
        globalLocation: CGPoint,
        location: CGPoint,
        radius: CGFloat
    ) {
        self.phase = phase
        self.timestamp = timestamp
        self.binding = binding
        self.globalLocation = globalLocation
        self.location = location
        self.radius = radius
    }
    
}
