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
extension View {
    
    public func scrollContentInsets(_ insets: EdgeInsets) -> some View {
        modifier(TransformScrollContentInsets(edges: .all, insets: insets))
    }
    
    public func scrollContentInsets(_ edges: Edge.Set = .all, _ length: CGFloat) -> some View {
        modifier(TransformScrollContentInsets(edges: edges, insets: EdgeInsets(top: length, leading: length, bottom: length, trailing: length)))
    }

}

@available(iOS 13.0, *)
private struct TransformScrollContentInsets: ViewModifier {
    
    private let edges: Edge.Set
    
    private let insets: EdgeInsets
    
    fileprivate init(edges: Edge.Set, insets: EdgeInsets) {
        self.edges = edges
        self.insets = insets
    }
    
    fileprivate func body(content: Content) -> some View {
        content
            .transformEnvironment(\.scrollContentInsets) { value in
                if edges.contains(.top) {
                    value.top = insets.top
                }
                if edges.contains(.leading) {
                    value.leading = insets.leading
                }
                if edges.contains(.bottom) {
                    value.bottom = insets.bottom
                }
                if edges.contains(.trailing) {
                    value.trailing = insets.trailing
                }
            }
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    internal var scrollContentInsets: EdgeInsets {
        get {
            self[ContentInsetsKey.self]
        }
        set {
            self[ContentInsetsKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct ContentInsetsKey: EnvironmentKey {
    
    fileprivate static var defaultValue: EdgeInsets {
        EdgeInsets()
    }
}
