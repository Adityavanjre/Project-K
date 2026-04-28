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
internal enum GesturePhase<Event> {

    case possible(Event?)

    case active(Event)

    case ended(Event)

    case failed
    
    internal var unwrapped: Event? {
        switch self {
        case let .possible(event):
            return event
        case let .active(event), let .ended(event):
            return event
        case .failed:
            return nil
        }
    }
    
    internal var isActive: Bool {
        switch self {
        case .active, .ended:
            return true
        default:
            return false
        }
    }
    
    internal var isTerminal: Bool {
        switch self {
        case .failed, .ended:
            return true
        default:
            return false
        }
    }
    
    internal var isFailed: Bool {
        switch self {
        case .failed:
            return true
        default:
            return false
        }
    }
    
    internal var isEnded: Bool {
        switch self {
        case .ended:
            return true
        default:
            return false
        }
    }
    
    /// Phases that cause or happen after `UIGestureRecognizer.State.began`.
    internal var hasBegan: Bool {
        switch self {
        case .possible:
            return false
        default:
            return true
        }
    }
    
    internal func and<AnotherEvent, MergedEvent>(_ anotherPhase: GesturePhase<AnotherEvent>, value: (Event, AnotherEvent) -> MergedEvent) -> GesturePhase<MergedEvent> {
        switch (self, anotherPhase) {
        case (_, .failed), (.failed, _):
            return .failed
        case (.possible, _), (_, .possible):
            return .possible(nil)
        case let (.active(event), .active(anotherEvent)),
             let (.ended(event), .active(anotherEvent)),
             let (.active(event), .ended(anotherEvent)):
            return .active(value(event, anotherEvent))
        case let (.ended(event), .ended(anotherEvent)):
            return .ended(value(event, anotherEvent))
        }
    }
    
    internal func set<AnotherEvent>(_ anotherEvent: AnotherEvent) -> GesturePhase<AnotherEvent> {
        map { _ in
            anotherEvent
        }
    }
    
    internal func map<TransformedEvent>(_ transform: (Event) -> TransformedEvent) -> GesturePhase<TransformedEvent> {
        switch self {
        case let .possible(event):
            return .possible(event.map({transform($0)}))
        case let .active(event):
            return .active(transform(event))
        case let .ended(event):
            return .ended(transform(event))
        case .failed:
            return .failed
        }
    }

    internal func withValue<AnotherEvent>(_ value: AnotherEvent?) -> GesturePhase<AnotherEvent> {
        switch self {
        case .possible(let eventOrNil):
            if eventOrNil != nil {
                return .possible(value)
            } else {
                return .possible(nil)
            }
        case .active:
            return .active(value!)
        case .ended:
            return .ended(value!)
        case .failed:
            return .failed
        }
    }
    
    internal var phaseValue: Event? {
        switch self {
        case .possible(let event):
            return event
        case .active(let event):
            return event
        case .ended(let event):
            return event
        case .failed:
            return nil
        }
    }

#if BINARY_COMPATIBLE_TEST || DEBUG
    internal var stateDescription: String {
        switch self {
        case .possible:
            return "possible"
        case .active:
            return "active"
        case .ended:
            return "ended"
        case .failed:
            return "failed"
        }
    }
#endif
    
}

@available(iOS 13.0, *)
extension GesturePhase: Defaultable {
    
    internal typealias Value = GesturePhase
    
    internal static var defaultValue: Value { .failed }
    
}

@available(iOS 13.0, *)
extension GesturePhase: Equatable where Event: Equatable { }
