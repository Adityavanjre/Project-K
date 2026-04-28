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
internal enum EventSourceType {
    case platformGestureRecognizer
    case platformHostingView
    case hoverGestureRecognizer
    case selectGestureRecognizer
}


@available(iOS 13.0, *)
internal class EventBindingBridge: NSObject, EventBindingManagerDelegate {
    
    internal weak var eventBindingManager: EventBindingManager?

    internal var responderWasBoundHandler: ((ResponderNode) -> Void)?

    private var trackedEvents: [EventID: TrackedEventState]

    internal var bindingActivateHandler: ((ResponderNode) -> Void)?

    internal var bindingUpdateHandler: ((ResponderNode) -> Void)?

    internal var bindingDeactivateHandler: ((ResponderNode) -> Void)?
    
    internal init(eventBindingManager: EventBindingManager) {
        self.eventBindingManager = eventBindingManager
        self.responderWasBoundHandler = nil
        self.trackedEvents = [:]
        super.init()
        if !DanceUIFeature.gestureContainer.isEnable {
            eventSources.forEach { $0.attach(to: self) }
        }
    }
    
    internal var eventSources: [EventBindingSource] {
        []
    }
    
    internal func source(for type: EventSourceType) -> EventBindingSource? {
        nil
    }
    
    internal func setInheritedPhase(_ phase: _GestureInputs.InheritedPhase) {
        eventBindingManager?.setInheritedPhase(phase)
    }
    
    @discardableResult
    internal func send(_ events: [EventID: EventType], source: EventBindingSource) -> Set<EventID> {
        
        var newDic: [EventID: EventType] = [:]
        
        for (id, type) in events {
            
            var trackedEvent = trackedEvents[id]
            
            if trackedEvent == nil && type.phase == .active {
                trackedEvent = TrackedEventState(sourceID: ObjectIdentifier(source), reset: false)
                trackedEvents[id] = trackedEvent
            }
            
            if type.phase != .active {
                trackedEvents[id] = nil
            }
            
            if trackedEvent?.reset == false {
                newDic[id] = type
            }
        }
        
        if !newDic.isEmpty {
            return eventBindingManager?.send(newDic) ?? Set()
        } else {
            return Set()
        }
    }

    internal func reset(eventSource: EventBindingSource, resetForwardedEventDispatchers: Bool) {
        for (id, status)  in trackedEvents where status.reset == true {
            if status.sourceID == AnyHashable(ObjectIdentifier(eventSource)) {
                trackedEvents[id] = nil
            }
        }
        eventBindingManager?.reset(resetForwardedEventDispatchers: resetForwardedEventDispatchers)
    }
    
    internal func didBind(to binding: EventBinding, id: EventID) {
        if let responderWasBoundHandler = responderWasBoundHandler {
            Update.perform {
                responderWasBoundHandler(binding.responder)
            }
        }
        if DanceUIFeature.gestureContainer.isEnable {
            for eachSource in eventSources {
                eachSource.didBind(to: binding, id: id, in: self)
            }
        }
    }
    
    internal func willActivateBinding(_ eventBinding: EventBinding, for id: EventID) {
        guard let handler = bindingActivateHandler else {
            return
        }
        Update.perform {
            handler(eventBinding.responder)
        }
    }
    
    internal func didUpdateBinding(_ eventBinding: EventBinding, for id: EventID) {
        guard let handler = bindingUpdateHandler else {
            return
        }
        Update.perform {
            handler(eventBinding.responder)
        }
        eventBindingManager?.delegate?.didBind(to: eventBinding, id: id)
    }
    
    internal func willDeactivateBinding(_ eventBinding: EventBinding, for id: EventID) {
        guard let handler = bindingDeactivateHandler else {
            return
        }
        Update.perform {
            handler(eventBinding.responder)
        }
    }
    
    internal func didUpdate(phase: GesturePhase<Void>, in manager: EventBindingManager) {
        for eachSource in eventSources {
            eachSource.didUpdate(phase: phase, in: self)
        }
        switch phase {
        case .ended, .failed:
            resetEvents()
        default:
            break
        }
    }
    
    internal func didUpdate(gestureCategory: GestureCategory, in manager: EventBindingManager) {
        for eachSource in eventSources {
            eachSource.didUpdate(gestureCategory: gestureCategory, in: self)
        }
    }
    
    private func resetEvents() {
        trackedEvents.keys.forEach {
            trackedEvents[$0]?.reset = true
        }
    }

}

@available(iOS 13.0, *)
extension EventBindingBridge {
    
    private struct TrackedEventState {

        internal var sourceID: AnyHashable

        internal var reset: Bool

    }
}
