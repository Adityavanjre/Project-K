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
internal protocol EventType {
    
    var phase: EventPhase { get }

    var timestamp: Time { get }

    var binding: EventBinding? { get set }

    init?(_ event: EventType)

    static var rebindsEachEvent: Bool { get }

    static var failsListenersIfUnmatched: Bool { get }
    
}

@available(iOS 13.0, *)
extension EventType {

    internal static var failsListenersIfUnmatched: Bool {
        true
    }
    
    internal static var rebindsEachEvent: Bool {
        false
    }
    
    internal var isFocusEvent: Bool {
        HitTestableEvent(self) == nil
    }
    
    internal init?(_ event: EventType) {
        guard let eventAsSelf = event as? Self else {
            return nil
        }
        self = eventAsSelf
    }

}
