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
import Foundation

@available(iOS 13.0, *)
internal protocol DynamicContainerItem {

    var count : Int { get }

    var needsTransitions : Bool { get }

    var layoutPriority : Double? { get }

    var zIndex : Double { get }

    func matchesIdentity(of: Self) -> Bool

    static var supportsReuse: Bool { get }

    var list: Attribute<ViewList>? { get }

    func canBeReused(by: Self) -> Bool

}

@available(iOS 13.0, *)
extension DynamicContainerItem {

    internal static var supportsReuse: Bool {
        false
    }

    internal func canBeReused(by: Self) -> Bool {
        false
    }

}
