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
extension Rule {
    
    @inline(__always)
    internal func makeAttribute() -> Attribute<Self.Value> {
        Attribute(self)
    }
    
}

@available(iOS 13.0, *)
extension StatefulRule {
    
    @inline(__always)
    internal func makeAttribute() -> Attribute<Self.Value> {
        Attribute(self)
    }
    
}

@available(iOS 13.0, *)
extension Attribute {
    
    internal var debuggable: Attribute<Value> {
#if DEBUG
        return self.subgraph.apply {
            let debuggable = DebuggableRule(observed: self).makeAttribute()
            debuggable.addInput(self, options: .sentinel, token: 0)
            return debuggable
        }
#else
        return self
#endif
    }
    
}

@available(iOS 13.0, *)
extension OptionalAttribute {
    
    internal var debuggable: OptionalAttribute<Value> {
#if DEBUG
        if let attribute {
            return OptionalAttribute(attribute.debuggable)
        } else {
            return OptionalAttribute()
        }
#else
        return self
#endif
    }
    
}

@available(iOS 13.0, *)
extension WeakAttribute {
    
    internal var debuggable: WeakAttribute<Value> {
#if DEBUG
        if let attribute {
            return WeakAttribute(attribute.debuggable)
        } else {
            return WeakAttribute()
        }
#else
        return self
#endif
    }
    
}

#if DEBUG
struct DebuggableRule<Value>: Rule {
    
    @Attribute
    var observed: Value
    
    var value: Value {
        let observed = observed
        print("[Debuggable] [\($observed.identifier)] [\(Value.self)] \(observed)")
        return observed
    }
}
#endif
