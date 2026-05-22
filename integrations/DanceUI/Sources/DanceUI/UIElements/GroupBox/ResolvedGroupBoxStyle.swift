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
internal struct ResolvedGroupBoxStyle: StyleableView {

    internal var configuration: GroupBoxStyleConfiguration
    /*
    typealias DefaultBody =
    ModifiedContent<
        ModifiedContent<
            ModifiedContent<
                ModifiedContent<
                    VStack<
                        TupleView<(
                            ModifiedContent<
                                ModifiedContent<
                                    GroupBoxStyleConfiguration.Label,
                                    _AlignmentLayout
                                >,
                                _EnvironmentKeyWritingModifier<Optional<Font>>
                            >,
                            GroupBoxStyleConfiguration.Content
                        )>
                    >,
                    _PaddingLayout
                >,
                _BackgroundModifier<
                    _ShapeView<RoundedRectangle, BackgroundStyle>
                >
            >,
            StyleContextWriter<ContainerStyleContext>
        >,
        SpacingLayout
    >
    */
    
    internal func defaultBody() -> some View {
        return PhoneIdiomGroupBoxStyle().makeBody(configuration: configuration)
    }
    
}

@available(iOS 13.0, *)
internal struct PhoneIdiomGroupBoxStyle: GroupBoxStyle {
        
    internal func makeBody(configuration: GroupBoxStyleConfiguration) -> some View {
        
        VStack {
            configuration.label
                .alignment(horizontal: .leading, vertical: nil)
                .environment(\.font, .headline)
            configuration.content
        }
        .padding()
        .background(RoundedRectangle(cornerSize: .init(width: 8.0, height: 8.0), style: .continuous).fill(BackgroundStyle()))
        .modifier(SpacingLayout(spacing: .zeroText))
    }
}

@frozen
@available(iOS 13.0, *)
public struct BackgroundStyle: Paint {
    
    @inlinable
    public init() {
        
    }
    
    internal func resolvePaint(in environment: EnvironmentValues) -> Color.Resolved {
        let c = Color._backgroundColor
        return c.resolvePaint(in: environment)
    }
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        Color._backgroundColor._apply(to: &shape)
    }
}
