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
internal struct HitTestingLayoutGesture: LayoutGesture {
    
    internal var responder: MultiViewResponder
    
    internal var bindChildExclusively: Bool
    
    internal func receive(events: [EventID : EventType], children: LayoutGestureChildBindings) {
        
        for (eventID, event) in events {
            
            guard let hitTestableEvent = HitTestableEvent(event) else {
                continue
            }
            
            guard let firstBoundChildIndex = children.firstIndex(where: { (child) -> Bool in
                child.wasBound(to: event)
            }) else {
                continue
            }
            
            let points = [hitTestableEvent.hitTestLocation]
            
            let firstBoundChild = children.child(at: firstBoundChildIndex)
            
            if !firstBoundChild.containsGlobalPoints(points, cacheKey: nil).contains(BitVector64(rawValue: 1)) {
                
                guard let firstHitChild = children.lastIndex(where: { (child) -> Bool in
                    child.containsGlobalPoints(points, cacheKey: nil).contains(BitVector64(rawValue: 1))
                }) else {
                    return
                }
                
                children.child(at: firstHitChild).bind(to: hitTestableEvent, id: eventID, hitTest: true)
                
                if bindChildExclusively {
                    firstBoundChild.unbindEvent(event, id: eventID)
                }
                
            }
            
        }
    }

}
