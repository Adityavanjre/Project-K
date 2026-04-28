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

@_spi(DanceUICompose) import DanceUI

@available(iOS 13, *)
internal final class ComposeCanvasContext: CustomDebugStringConvertible {

    internal init() {}
    
    @inline(__always)
    internal var identityContainer: ComposeDisplayListIdentityContainer?

    @inline(__always)
    internal var identity: DisplayList.Identity {
        Signpost.compose.tracePoi("CanvasContext:getIdentity", []) {
            guard let identityContainer else {
                _danceuiRuntimeIssue(type: .error, "identity container is not set")
                return .make()
            }
            return identityContainer.getValue(forReading: false)
        }
    }
    
    func getIdentityValue(forReading: Bool) -> DisplayList.Identity {
        Signpost.compose.tracePoi("CanvasContext:getIdentityValue", []) {
            guard let identityContainer else {
                _danceuiRuntimeIssue(type: .error, "identity container is not set")
                return .make()
            }
            return identityContainer.getValue(forReading: forReading)
        }
    }

    internal var effects: EffectsBuffer<EffectStorage> = .init()
    
    internal var opacity: CGFloat = 1.0
    
    internal var environment: EnvironmentValues = .init()

    internal var result: DisplayList = .empty
    
    internal var debugDescription: String {
        result.minimalDebugDescription
    }
    
    internal struct EffectStorage {
        internal let effect: DisplayList.Effect
        internal let bounds: CGRect
        internal let identity: DisplayList.Identity
    }
    
    internal func reset() {
        identityContainer?.reset()
        effects.reset()
        opacity = 1.0
        environment = .init()
        result = .empty
    }
}

@available(iOS 13, *)
internal struct EffectsBuffer<T> {
    internal private(set) var buffer: [T?] = []
    internal private(set) var count: Int = 0

    internal init() {
        let id = Signpost.compose.tracePoiBegin("EffectBuffer:init", [])
        self.buffer.reserveCapacity(16)
        Signpost.compose.tracePoiEnd(id: id, "EffectBuffer:init", [])
    }

    @inline(__always)
    internal mutating func append(_ effect: T) {
        Signpost.compose.tracePoi("EffectBuffer:append", []) {
            if count < buffer.count {
                buffer[count] = effect
            } else {
                buffer.append(effect)
            }
            count += 1
        }
    }

    @inline(__always)
    internal mutating func removeLast(_ k: Int) {
        Signpost.compose.tracePoi("EffectBuffer:removeLast", []) {
            let k = min(k, count)
            let newCount = count - k
            // Nil out the removed elements to release references.
            for i in newCount..<count {
                buffer[i] = nil
            }
            count = newCount
        }
    }

    @inline(__always)
    internal subscript(index: Int) -> T? {
        get {
            guard index < count else {
                // This should not happen in normal use, but as a safeguard.
                return nil
            }
            return buffer[index]
        }
    }
    
    @inline(__always)
    internal mutating func reset() {
        count = 0
    }
}
