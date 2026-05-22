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

/// A view that doesn't contain any content.
///
/// You will rarely, if ever, need to create an `EmptyView` directly. Instead,
/// `EmptyView` represents the absence of a view.
///
/// DanceUI uses `EmptyView` in situations where a DanceUI view type defines one
/// or more child views with generic parameters, and allows the child views to
/// be absent. When absent, the child view's type in the generic type parameter
/// is `EmptyView`.
///
/// The following example creates an indeterminate ``ProgressView`` without
/// a label. The ``ProgressView`` type declares two generic parameters,
/// `Label` and `CurrentValueLabel`, for the types used by its subviews.
/// When both subviews are absent, like they are here, the resulting type is
/// `ProgressView<EmptyView, EmptyView>`, as indicated by the example's output:
///
///     let progressView = ProgressView()
///     print("\(type(of:progressView))")
///     // Prints: ProgressView<EmptyView, EmptyView>
///
@frozen
@available(iOS 13.0, *)
public struct EmptyView : View, PrimitiveView {
    
    /// Creates an empty view.
    @inlinable
    public init() {
    }
    
    public static func _makeView(view: _GraphValue<EmptyView>, inputs: _ViewInputs) -> _ViewOutputs {
        .initialOutputs
    }
    
    public static func _makeViewList(view: _GraphValue<EmptyView>, inputs: _ViewListInputs) -> _ViewListOutputs {
        guard inputs.hasParent else {
            return .staticList(EmptyViewListElements(), inputs: inputs, staticCount: 0)
        }
        return .nonEmptyParentViewList(inputs: inputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        inputs.options.contains(.hasParent) ? 1 : 0
    }
}
