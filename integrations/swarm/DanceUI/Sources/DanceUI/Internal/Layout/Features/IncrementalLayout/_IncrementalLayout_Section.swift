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
internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct _IncrementalLayout_Section {

    internal var base: _ViewList_Section

    internal var transform: _ViewList_SublistTransform

    internal var cache: ViewCache

    internal var context: DanceUIGraph.AnyRuleContext

    internal var header: _IncrementalLayout_Children {
        _IncrementalLayout_Children(cache: cache,
                                    context: context,
                                    node: .list(base.base.lists[0]),
                                    transform: transform,
                                    section: ViewCache.Section(id: base.id, isHeader: true, isFooter: false))
    }

    internal var content: _IncrementalLayout_Children {
        _IncrementalLayout_Children(cache: cache,
                                    context: context,
                                    node: .list(base.base.lists[1]),
                                    transform: transform,
                                    section: ViewCache.Section(id: base.id, isHeader: false, isFooter: false))
    }

    internal var footer: _IncrementalLayout_Children {
        _IncrementalLayout_Children(cache: cache,
                                    context: context,
                                    node: .list(base.base.lists[2]),
                                    transform: transform,
                                    section: ViewCache.Section(id: base.id, isHeader: false, isFooter: true))
    }
}
