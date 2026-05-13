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
internal struct NavigationViewStyleModifier<Style: NavigationViewStyle>: StyleModifier {

    internal typealias Style = Style
    
    internal typealias Subject = ResolvedNavigationViewStyle
    
    internal typealias SubjectBody = Style._Body

    internal var style: Style
    
    static func body(view: ResolvedNavigationViewStyle, style: Style) -> Style._Body {
        style._body(configuration: _NavigationViewStyleConfiguration())
    }

}

@available(iOS 13.0, *)
extension View {
  
    /// Sets the style for navigation views within this view.
    ///
    /// Use this modifier to change the appearance and behavior of navigation
    /// views. For example, by default, navigation views appear with multiple
    /// columns in wider environments, like iPad in landscape orientation:
    ///
    ///
    /// You can apply the ``NavigationViewStyle/stack`` style to force
    /// single-column stack navigation in these environments:
    ///
    ///     NavigationView {
    ///         List {
    ///             NavigationLink("Purple", destination: ColorDetail(color: .purple))
    ///             NavigationLink("Pink", destination: ColorDetail(color: .pink))
    ///             NavigationLink("Orange", destination: ColorDetail(color: .orange))
    ///         }
    ///         .navigationTitle("Colors")
    ///
    ///         Text("Select a Color") // A placeholder to show before selection.
    ///     }
    ///     .navigationViewStyle(.stack)
    ///
    public func navigationViewStyle<S: NavigationViewStyle>(_ style: S) -> some View {
        self.modifier(NavigationViewStyleModifier(style: style))
    }
  
}
