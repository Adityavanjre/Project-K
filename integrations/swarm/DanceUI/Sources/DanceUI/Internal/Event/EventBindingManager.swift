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
internal protocol ForwardedEventDispatcher {

    var eventType : EventType.Type { get }

    var isActive : Bool {get }

    func wantsEvent(_ event: EventType, manager: EventBindingManager) -> Bool

    func receiveEvents(_ dict: [EventID : EventType], manager: EventBindingManager) -> Set<EventID>

    func reset()

}

@available(iOS 13.0, *)
internal class EventBindingManager {
    
    internal weak var host: EventGraphHost?

    internal weak var delegate: EventBindingManagerDelegate?

    internal private(set) var forwardedEventDispatchers: [ObjectIdentifier : ForwardedEventDispatcher]

    internal var eventBindings: [EventID: EventBinding]

    internal var isActive: Bool

    internal var eventTimer: Timer?
    
    internal init() {
        self.host = nil
        self.delegate = nil
        self.forwardedEventDispatchers = [:]
        self.eventBindings = [:]
        self.isActive = false
        self.eventTimer = nil
    }
    
    deinit {
        eventTimer?.invalidate()
    }
    
    internal static var current: EventBindingManager? {
        ViewGraph.viewRendererHost?.eventBindingManager
    }
    
    @available(*, deprecated, message: "Remove when gesture container is verified.")
    internal func bindingForEvent(_ eventID: EventID) -> EventBinding? {
        eventBindings[eventID]
    }
    
    internal func addForwardedEventDispatchers(_ dispatcher: ForwardedEventDispatcher) {
        forwardedEventDispatchers[ObjectIdentifier(type(of: dispatcher))] = dispatcher
    }
    
    internal func rebindEvent(_ eventID: EventID, to responder: ResponderNode?) -> ResponderNode? {
        guard var binding = eventBindings[eventID] else {
            return nil
        }
        
        let originalNode = binding.responder
        if let responder = responder {
            binding.isRedirected = true
            binding.responder = responder
            eventBindings[eventID] = binding
        } else {
            eventBindings[eventID] = nil
        }
        return originalNode
    }
    
    internal var rootResponder: ResponderNode? {
        host?.responderNode
    }
    
    internal var focusedResponder: ResponderNode? {
        host?.focusedResponder
    }
    
    internal func reset(resetForwardedEventDispatchers: Bool = false) {
        Update.enqueueAction { [weak self] in
            if DanceUIFeature.gestureContainer.isEnable {
                self?.host?.resetEvents()
            } else {
                let host = self?.host?.eventBindingManager.host as? ViewRendererHost
                host?.viewGraph.resetEvents()
            }
        }
        if DanceUIFeature.gestureContainer.isEnable {
            if resetForwardedEventDispatchers {
                for (_, dispatcher) in forwardedEventDispatchers {
                    dispatcher.reset()
                }
            }
        }
        if let delegate = self.delegate {
            for (id, binding) in eventBindings {
                delegate.willDeactivateBinding(binding, for: id)
            }
        }
        eventBindings = [:]
        if DanceUIFeature.gestureContainer.isEnable {
            eventTimer?.invalidate()
        }
        isActive = false
    }
    
    internal func setInheritedPhase(_ phase: _GestureInputs.InheritedPhase) {
        guard let host else {
            return
        }
        Update.perform {
            host.setInheritedPhase(phase)
            self.send([:])
        }
    }
    
    internal func send<A: EventType>(_ event: A, id: Int) {
        send([EventID(type: A.self, serial: id) : event])
    }
    
    @discardableResult
    internal func send(_ events: [EventID: EventType]) -> Set<EventID> {
        if DanceUIFeature.gestureContainer.isEnable {
            return Update.perform { [weak self] in
                return self?.sendDownstream(events) ?? Set()
            }
        } else {
            Update.enqueueAction { [weak self] in
                _ = self?.sendDownstream(events)
            }
            return Set()
        }
    }
    
    internal func binds<A: EventType>(_ event: A) -> Bool {
        forwardedEventDispatchers[ObjectIdentifier(A.self)]?.wantsEvent(event, manager: self) ?? false
    }
    
    internal func willRemoveResponder(_ responder: ResponderNode) {
        let nextResponder = responder.nextResponder
        for (key, var value) in eventBindings {
            if DanceUIFeature.gestureContainer.isEnable {
                for node in value.responder.sequenceFeatureGestureContainer where responder === node {
                    if let nextNode = nextResponder {
                        value.responder = nextNode
                        eventBindings[key] = value
                    } else {
                        eventBindings[key] = nil
                    }
                    break
                }
            } else {
                for node in value.responder.sequence where responder === node {
                    if let nextNode = nextResponder {
                        value.responder = nextNode
                        eventBindings[key] = value
                    } else {
                        eventBindings[key] = nil
                    }
                    break
                }
            }
        }
    }
    
    private func scheduleNextEventUpdate(time: Time) {
        eventTimer?.invalidate()
        eventTimer = nil
        let diffTime = time - Time.now
        if diffTime > .zero && diffTime != .distantFuture {
            eventTimer = withDelay(diffTime.seconds) { [weak self] in
                self?.send([:])
            }
        }
    }
    
    internal func isActive<A: EventType>(for eventType: A.Type) -> Bool {
        guard let dispatcher = self.forwardedEventDispatchers[ObjectIdentifier(eventType)] else {
            return self.isActive
        }
        
        return dispatcher.isActive
    }
    
    internal func point(inside globalPoint: CGPoint, with event: UIEvent?) -> Bool {
        guard let host = host else {
            return false
        }

        let event = TouchEvent(
            timestamp: event?.timestamp.toTime() ?? .zero,
            phase: .active,
            binding: nil,
            location: .zero,
            globalLocation: globalPoint,
            radius: 44,
            force: 0,
            maximumPossibleForce: 0
        )
        
        return host.responderNode?.bindEvent(event) != nil
    }
    
    private func sendDownstream(_ events: [EventID: EventType]) -> Set<EventID> {
        guard let host = host else {
            return []
        }
        
        let responderNodeOrNil = host.responderNode
        let focusedResponder = host.focusedResponder
        _eventDebugTriggers = .responders
        
#if DEBUG
        if EnvValue.isPrintHitTestEnabled {
            (responderNodeOrNil as? ViewResponder)?.printTree()
        }
#endif
        
        printEvents(.sendEvents, events: events)
        
        // let nonGestureEventsConsumed = dispatchNonGestureEvents(events)

        var notActiveEvents: [EventID] = []
        
        var boundEvents = [EventID : EventType]()
        boundEvents.reserveCapacity(events.count)
        
        for (id, var type) in events {
            if let existBinding = eventBindings[id] {
                if existBinding.isFirstEvent {
                    eventBindings[id] = EventBinding(
                        responder: existBinding.responder,
                        isFirstEvent: false,
                        isRedirected: existBinding.isRedirected
                    )
                }
                
                type.binding = existBinding
                boundEvents[id] = type

                switch type.phase {
                case .active:
                    delegate?.didUpdateBinding(existBinding, for: id)
                case .ended:
                    delegate?.willDeactivateBinding(existBinding, for: id)
                case .failed:
                    delegate?.willDeactivateBinding(existBinding, for: id)
                }
                
            } else {
                let newNode: ResponderNode?
                if let focused = focusedResponder, type.isFocusEvent {
                    newNode = focused.bindEvent(type)
                } else {
                    newNode = responderNodeOrNil?.bindEvent(type)
                }
                
                if let responder = newNode {
                    let eventBinding = EventBinding(
                        responder: responder,
                        isFirstEvent: true,
                        isRedirected: false
                    )
                    eventBindings[id] = eventBinding
                    type.binding = eventBinding
                    boundEvents[id] = type
                    
                    isActive = true
                    
                    delegate?.didBind(to: eventBinding, id: id)

                    delegate?.willActivateBinding(eventBinding, for: id)
                }
            }
            
            if type.phase != .active {
                notActiveEvents.append(id)
            }

        }
        
        printEventBindings(.eventBindings, bindings: eventBindings)
        
        if let responderNode = responderNodeOrNil, isActive {
            // ViewRendererHost (a.k.a the EventGraphHost when gesture container
            // is disabled) implements `sendEvents` as:
            //
            // ```
            // func sendEvents(_ events: [EventID : any EventType], rootNode: ResponderNode, at time: Time) -> EventOutputs {
            //     updateViewGraph { viewGraph in
            //         viewGraph.sendEvents(events, rootNode: rootNode, at: time)
            //     }
            // }
            // ```
            //
            // Thus we don't need to check feature toggle at this place.
            let eventOutputs = host.sendEvents(boundEvents, rootNode: responderNode, at: .now)
            responderNode.log(.eventPhases, action: "root-phase", data: eventOutputs.gesturePhase)
            
            let nextUpdateTime: Time
            if DanceUIFeature.gestureContainer.isEnable {
                nextUpdateTime = host.nextGestureUpdateTime
                if let category = host.gestureCategory() {
                    delegate?.didUpdate(gestureCategory: category, in: self)
                }
                
                delegate?.didUpdate(phase: eventOutputs.gesturePhase, in: self)
            } else {
                delegate?.didUpdate(phase: eventOutputs.gesturePhase, in: self)
                nextUpdateTime = host.nextGestureUpdateTime
            }
            
            if nextUpdateTime < .distantFuture {
                scheduleNextEventUpdate(time: nextUpdateTime)
            }
        }
        
        for event in notActiveEvents {
            eventBindings.removeValue(forKey: event)
        }
        
        return Set(events.keys.filter({notActiveEvents.contains($0)}))
    }
    
}

@available(iOS 13.0, *)
internal func printEvents(_: _EventDebugTriggers, events: [EventID : EventType]) {
    #warning("_notImplemented()")
}

@available(iOS 13.0, *)
internal func printEventBindings(_: _EventDebugTriggers, bindings: [AnyHashable : EventBinding]) {
    #warning("_notImplemented()")
}
