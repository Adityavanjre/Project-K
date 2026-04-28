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
extension Trace.ActionName {
    
    // MARK: Object Life-Cycle Common Action
    
    internal static let create = ActionName("Create")
    
    internal static let update = ActionName("Update")
    
    internal static let destroy = ActionName("Destroy")
    
    internal static let reset = ActionName("Reset")
    
    // MARK: Resource Accessing Common Action
    
    internal static let access = ActionName("Access")
    
    // MARK: Cache Common Action
    
    internal static let hit = ActionName("Hit")
    
    internal static let miss = ActionName("Miss")
    
    // MARK: Value Testing Common Actions
    
    internal static let test = ActionName("Test")
    
    // MARK: Attribute Common Events
    
    /// Event for `Attribute.invalidateValue`.
    ///
    internal static let invalidateValue = ActionName("InvalidateValue")
    
    // MARK: Graph Mutation Common Events
    
    internal static let combine = ActionName("Combine")
    
    // MARK: Swift Collection Related Events
    
    internal static let append = ActionName("Append")
    
    internal static let removeFirst = ActionName("RemoveFirst")
    
    internal static let removeLast = ActionName("RemoveLast")
    
    internal static let commitGraphMutation = ActionName("CommitGraphMutation")
    
}

#if DEBUG || DANCE_UI_INHOUSE
@available(iOS 13.0, *)
internal protocol GraphMutationTraceMetadata: TraceMetadataProtocol {
    
    var name: String { get }
    
}
#else
@available(iOS 13.0, *)
internal typealias GraphMutationTraceMetadata = TraceMetadataProtocol
#endif

@available(iOS 13.0, *)
internal struct SignalAttributeChangedValueTraceMetadata: TraceMetadataProtocol {
    
    internal let identifier: UInt32
    
    internal var isChanged: Bool
    
    // Trivial init

    @inlinable
    internal init(attribute: DGWeakAttribute, isChanged: Bool) {
        self.init(attribute: attribute.attribute ?? .nil, isChanged: isChanged)
    }
    
    // Trivial init

    @inlinable
    internal init<T>(attribute: WeakAttribute<T>, isChanged: Bool) {
        self.init(attribute: attribute.base, isChanged: isChanged)
    }
    
    // Trivial init
    // BDCOV_EXCL_FUNC
    @inlinable
    internal init<T>(attribute: Attribute<T>, isChanged: Bool) {
        self.init(attribute: attribute.identifier, isChanged: isChanged)
    }
    
    // Trivial init

    @inlinable
    internal init(attribute: DGAttribute, isChanged: Bool) {
        self.identifier = attribute.rawValue
        self.isChanged = isChanged
    }
    
}

@available(iOS 13.0, *)
internal struct SignalAttributeInvalidateValueTraceMetadata: TraceMetadataProtocol {
    
    internal let identifier: UInt32
    
    // Trivial init
    // BDCOV_EXCL_FUNC
    @inlinable
    internal init<T>(attribute: WeakAttribute<T>) {
        self.init(attribute: attribute.base)
    }
    
    // Trivial init
    // BDCOV_EXCL_FUNC
    @inlinable
    internal init(attribute: DGWeakAttribute) {
        self.init(attribute: attribute.attribute ?? .nil)
    }
    
    // Trivial init

    @inlinable
    internal init<T>(attribute: Attribute<T>) {
        self.init(attribute: attribute.identifier)
    }
    
    // Trivial init

    @inlinable
    internal init(attribute: DGAttribute) {
        self.identifier = attribute.rawValue
    }
    
}
