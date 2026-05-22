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
internal struct UpdateCycleDetector {
    
    @Attribute
    internal var updateSeed: UInt32
    
    internal var lastSeed: UInt32
    
    internal var ttl: UInt32
    
    internal var hasLogged: Bool
    
    @inlinable
    internal init() {
        _updateSeed = ViewGraph.current.$updateSeed
        lastSeed = .max
        ttl = 0
        hasLogged = false
    }
    
    @inlinable
    internal mutating func reset() {
        lastSeed = .max
        ttl = 0
        hasLogged = false
    }
    
    private var hasNoTimeToLive: Bool {
        mutating get {
            guard ttl != 0 else {
                return false
            }
            ttl = ttl &- 1
            return ttl != 0
        }
    }
    
    internal mutating func noCyclicUpdate(on action: @autoclosure () -> String, shouldLogCyclicUpdate: Bool) -> Bool {
        let updateSeed = DGGraphRef.withoutUpdate {
            self.updateSeed
        }
        
        if self.lastSeed == updateSeed {
            if hasNoTimeToLive {
                if shouldLogCyclicUpdate && !hasLogged {
                    log(action: action)
                    hasLogged = true
                }
            }
        } else {
            self.lastSeed = updateSeed
            ttl = 2
        }
        
        return ttl != 0
    }
    
    private func log(action: () -> String) {
        logger.warning("\(action()) tried to update multiple times per frame.")
    }
    
}
