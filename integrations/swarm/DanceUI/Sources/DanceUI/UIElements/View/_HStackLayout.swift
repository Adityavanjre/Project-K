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

@frozen
@available(iOS 13.0, *)
public struct _HStackLayout: HVStack, _VariadicView_ImplicitRoot {
    
    public typealias AnimatableData = EmptyAnimatableData
    
    public typealias Body = Never
    
    internal typealias MinorAxisAlignment = VerticalAlignment
    
    internal typealias PlacementContextType = PlacementContext
    
    internal static let isIdentityUnaryLayout: Bool = true
    
    // 0x0
    public var alignment: VerticalAlignment
    
    // 0x8
    public var spacing: CGFloat?
    
    @inlinable
    public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }
    
    internal static var majorAxis: Axis {
        .horizontal
    }
    
    internal static var resizeChildrenWithTrailingOverflow: Bool {
        false
    }
    
    internal static var implicitRoot: _HStackLayout {
        .init(alignment: .center, spacing: nil)
    }
}
