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
public struct GestureExtendedConfigs {
    
    internal static let empty = GestureExtendedConfigs()
    
    public let shouldBeRequiredToFailBy: Set<Namespace.ID>
    
    public let shouldRequireFailureOf: Set<Namespace.ID>
    
    public let shouldRecognizeSimultaneouslyWith: Set<Namespace.ID>
    
    public init(shouldBeRequiredToFailBy: Set<Namespace.ID> = [],
                shouldRequireFailureOf: Set<Namespace.ID> = [],
                shouldRecognizeSimultaneouslyWith: Set<Namespace.ID> = []) {
        self.shouldBeRequiredToFailBy = shouldBeRequiredToFailBy
        self.shouldRequireFailureOf = shouldRequireFailureOf
        self.shouldRecognizeSimultaneouslyWith = shouldRecognizeSimultaneouslyWith
    }
    
    public func shouldBeRequiredToFail(by gestureID: Namespace.ID) -> GestureExtendedConfigs {
        GestureExtendedConfigs(shouldBeRequiredToFailBy: shouldBeRequiredToFailBy.union([gestureID]),
                               shouldRequireFailureOf: shouldRequireFailureOf,
                               shouldRecognizeSimultaneouslyWith: shouldRecognizeSimultaneouslyWith)
    }
    
    public func shouldRequireFailure(of gestureID: Namespace.ID) -> GestureExtendedConfigs {
        GestureExtendedConfigs(shouldBeRequiredToFailBy: shouldBeRequiredToFailBy,
                               shouldRequireFailureOf: shouldRequireFailureOf.union([gestureID]),
                               shouldRecognizeSimultaneouslyWith: shouldRecognizeSimultaneouslyWith)
    }
    
    public func shouldRecognizeSimultaneously(with gestureID: Namespace.ID) -> GestureExtendedConfigs {
        GestureExtendedConfigs(shouldBeRequiredToFailBy: shouldBeRequiredToFailBy,
                               shouldRequireFailureOf: shouldRequireFailureOf,
                               shouldRecognizeSimultaneouslyWith: shouldRecognizeSimultaneouslyWith.union([gestureID]))
    }
    
    @inline(__always)
    internal var gestureRecognitionWitness: GestureRecognitionWitness {
        GestureRecognitionWitness(shouldBeRequiredToFailBy: Set(shouldBeRequiredToFailBy.map({.namespaced($0)})),
                                  shouldRequireFailureOf: Set(shouldRequireFailureOf.map({.namespaced($0)})),
                                  shouldRecognizeSimultaneouslyWith: Set(shouldRecognizeSimultaneouslyWith.map({.namespaced($0)})))
    }
    
}
