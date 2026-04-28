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

// TODO: SelectionManage, SelectionManagerBox, OptionalSelectionManagerProjection, SetSelectionManagerProjection unused
//@available(iOS 13.0, *)
//internal protocol SelectionManager {
//    
//    associatedtype SelectionValue
//    
//    mutating func select(_ value: SelectionValue)
//    
//    mutating func deselect(_ value: SelectionValue)
//    
//    func isSelected(_ value: SelectionValue) -> Bool
//}
//
//@available(iOS 13.0, *)
//internal enum SelectionManagerBox<SelectionValue : Hashable> : SelectionManager {
//    
//    case set(Set<SelectionValue>)
//
//    case optional(SelectionValue?)
//
//    internal init(_ values: Set<SelectionValue>) {
//        self = .set(values)
//    }
//    
//    internal init(_ value: SelectionValue?) {
//        self = .optional(value)
//    }
//    
//    internal mutating func select(_ value: SelectionValue) {
//        switch self {
//        case .set(var set):
//            set.insert(value)
//            self = .set(set)
//        case .optional(_):
//            self = .optional(value)
//        }
//    }
//    
//    internal mutating func deselect(_ value: SelectionValue) {
//        switch self {
//        case .set(var set):
//            set.remove(value)
//            self = .set(set)
//        case .optional(let optional):
//            if optional == value {
//                self = .optional(nil)
//            }
//        }
//    }
//    
//    internal func isSelected(_ value: SelectionValue) -> Bool {
//        switch self {
//        case .set(let set):
//            return set.contains(value)
//        case .optional(let optional):
//            return optional == value
//        }
//    }
//}
//
//@available(iOS 13.0, *)
//internal struct OptionalSelectionManagerProjection<SelectionValue : Hashable> : Projection {    
//
//    internal typealias Base = SelectionValue?
//
//    internal typealias Projected = SelectionManagerBox<SelectionValue>
//    
//    internal func get(base: Base) -> Projected {
//        SelectionManagerBox(base)
//    }
//    
//    internal func set(base: inout Base, newValue: Projected) {
//        switch newValue {
//        case .set(let set):
//            base = set.first
//        case .optional(let optional):
//            base = optional
//        }
//    }
//}
//
//@available(iOS 13.0, *)
//internal struct SetSelectionManagerProjection<SelectionValue : Hashable> : Projection {
//    
//    internal typealias Base = Set<SelectionValue>
//
//    internal typealias Projected = SelectionManagerBox<SelectionValue>
//    
//    internal func get(base: Base) -> Projected {
//        SelectionManagerBox(base)
//    }
//    
//    internal func set(base: inout Base, newValue: Projected) {
//        switch newValue {
//        case .set(let set):
//            base = set
//        case .optional(let optional):
//            base = optional.map { value in
//                Set([value])
//            } ?? Set()
//        }
//    }
//}
