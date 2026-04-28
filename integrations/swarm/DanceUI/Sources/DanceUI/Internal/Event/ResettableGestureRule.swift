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

internal import DanceUIGraph

@available(iOS 13.0, *)
internal protocol ResettableGestureRule: StatefulRule {
    
    associatedtype Value = GesturePhase<PhaseValue>
    
    associatedtype PhaseValue
    
    var phaseValue: Value { get }

    var resetSeed: UInt32 { get }

    var reset: GestureReset { get set }

    mutating func resetPhase()
    
}

@available(iOS 13.0, *)
extension ResettableGestureRule {
    
    internal var phaseValue: Value {
        optionalValue!
    }

    internal mutating func resetPhase() {
        
    }
    
}

@available(iOS 13.0, *)
extension ResettableGestureRule where Value == GesturePhase<PhaseValue> {
    
    @inline(__always)
    internal mutating func resetIfNeeded() -> Bool {
        defer {
            reset.seed = resetSeed
        }
        
        guard resetSeed == reset.seed else {
            resetPhase()
            return true
        }
        
        if let oldValue = self.optionalValue, oldValue.isTerminal {
            return false
        }
        
        return true
    }
    
    @available(*, deprecated, message: "Use resetIfNeeded() to adopt new design.")
    @discardableResult
    @inline(__always)
    internal func resetIfNeeded(_ reset: inout GestureReset, _ resetter: () -> Void = {}) -> Bool {
        guard resetSeed == reset.seed else {
            reset.seed = resetSeed
            resetter()
            return true
        }
        
        guard let value = optionalValue else {
            return true
        }
        
        let flag = !value.isTerminal
        return flag
    }
    
}
