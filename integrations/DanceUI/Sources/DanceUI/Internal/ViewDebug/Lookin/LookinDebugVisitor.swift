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

#if DEBUG || DANCE_UI_INHOUSE

import Foundation

@available(iOS 13.0, *)
extension Array where Element == LookinDebugData {
    internal func visitData<Visitor: LookinDebugVisitor>(_ visitor: inout Visitor) {
        visitor.visit(self)
    }
}

@available(iOS 13.0, *)
internal protocol LookinDebugVisitor {

    mutating func visit(_ datas: [LookinDebugData])
}

@available(iOS 13.0, *)
internal struct LookinVisitor: LookinDebugVisitor {
    
    internal var transform: ViewTransform
    
    private var views = [[String: Any]]()
    
    internal init(_ transform: ViewTransform) {
        self.transform = transform
    }

    internal mutating func visit(_ datas: [LookinDebugData]) {
        _visitInternal(datas, customViews: &views)
    }

    private func _visitInternal(_ datas: [LookinDebugData], customViews: inout [[String: Any]], modifierProperties: [[String: Any]] = []) {
        datas.forEach { data in
            var view = data.customSubviews(transform)
            var properties: [[String: Any]] = data.customProperties
            properties.append(contentsOf: modifierProperties)
            if !view.isEmpty {
                var subViews = [[String: Any]]()
                _visitInternal(data.children, customViews: &subViews)
                view["subviews"] = subViews
                view["properties"] = properties
                customViews.append(view)

            } else {
                _visitInternal(data.children, customViews: &customViews, modifierProperties: properties)
            }
        }
    }

    internal var lookinCustomSubviews: [[String: Any]] {
        views
    }
}

#endif
