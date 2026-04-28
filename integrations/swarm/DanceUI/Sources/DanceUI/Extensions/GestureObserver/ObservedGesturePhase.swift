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
public enum ObservedGesturePhase<Value> {
    
    case possible(Value?)
    
    case active(Value)
    
    case ended(Value)
    
    case failed
    
    public var value: Value? {
        switch self {
        case .possible(let value):
            return value
        case .active(let value),
             .ended(let value):
            return value
        case .failed:
            return nil
        }
    }
    
    public var isTerminal: Bool {
        switch self {
        case .ended, .failed:
            return true
        default:
            return false
        }
    }
    
    public func set<T>(_ value: T) -> ObservedGesturePhase<T> {
        switch self {
        case .possible(let x):
            return .possible(x == nil ? nil : value)
        case .active:
            return .active(value)
        case .ended:
            return .ended(value)
        case .failed:
            return .failed
        }
    }
    
}

@available(iOS 13.0, *)
extension ObservedGesturePhase: Equatable where Value: Equatable {
    
}
