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
public struct _VStackLayout: HVStack, _VariadicView_ImplicitRoot {
    
    internal static var majorAxis: Axis {
        .vertical
    }
    
    public var spacing: CGFloat?
    
    public var alignment: HorizontalAlignment
    
    internal static let isIdentityUnaryLayout: Bool = true
    
    internal typealias PlacementContextType = PlacementContext
    
    internal static var resizeChildrenWithTrailingOverflow: Bool {
        false
    }
    
    internal static var implicitRoot: _VStackLayout {
        .init(alignment: .center, spacing: nil)
    }
    
    @inlinable
    public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }
}

@available(iOS 13.0, *)
extension _VStackLayout: _VariadicView_UnaryViewRoot {
    
    public typealias AnimatableData = EmptyAnimatableData
    
    public typealias Body = Never
    
}

@available(iOS 13.0, *)
extension _VStackLayout: _VariadicView_ViewRoot {}

@available(iOS 13.0, *)
extension _VStackLayout: Animatable {}
