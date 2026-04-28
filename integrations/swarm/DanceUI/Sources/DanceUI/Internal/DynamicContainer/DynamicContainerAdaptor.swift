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
internal protocol DynamicContainerAdaptor {

    associatedtype Item: DynamicContainerItem

    associatedtype Items

    associatedtype ItemLayout

    var maxUnusedItems: Int { get }

    func updatedItems() -> Self.Items?

    func foreachItem(_: Self.Items, _: (Self.Item) -> ())

    static func containsItem(_: Self.Items, _: Self.Item) -> Bool

    func makeItemLayout(item: Self.Item, uniqueId: UInt32, inputs: _ViewInputs, containerInfo: Attribute<DynamicContainer.Info>, containerInputs: (inout _ViewInputs) -> Void) -> (_ViewOutputs, Self.ItemLayout)

    func removeItemLayout(uniqueId: UInt32, itemLayout: Self.ItemLayout)

    static func destroyItemLayout(_: Self.ItemLayout)
}

@available(iOS 13.0, *)
extension DynamicContainerAdaptor {

    internal var maxUnusedItems: Int { 0 }

}
