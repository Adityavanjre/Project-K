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
internal struct _ViewList_SublistTransform {

    internal var items: [_ViewList_SublistTransform_Item]

    @inline(__always)
    internal init() {
        items = []
        items.reserveCapacity(20)
    }

    @inline(__always)
    internal mutating func push<TransformItem: _ViewList_SublistTransform_Item>(_ item: TransformItem) {
        items.append(item)
    }

    @inline(__always)
    internal mutating func pop() {
        items.removeLast()
    }

    internal func apply(sublist: inout _ViewList_Sublist) {
        items.forEach({ $0.apply(sublist: &sublist) })
    }
}

@available(iOS 13.0, *)
internal protocol _ViewList_SublistTransform_Item {

    func apply(sublist: inout _ViewList_Sublist)

}
