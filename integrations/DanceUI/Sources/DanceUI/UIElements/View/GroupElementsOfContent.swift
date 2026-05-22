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

@available(iOS 13.0, *)
public struct GroupElementsOfContent<Subviews, Content>: View where Subviews: View, Content: View {
    internal let storage: Storage

    internal let content: (SubviewsCollection) -> Content
    
    internal init(subviews: Subviews, content: @escaping (SubviewsCollection) -> Content) {
        if let viewCollection = subviews as? SubviewsCollection {
            self.storage = .subviewsCollection(viewCollection)
        } else {
            self.storage = .view(subviews)
        }
        self.content = content
    }
    
    public var body: some View {
        switch storage {
        case .subviewsCollection(let subviewsCollection):
            content(subviewsCollection)
        case .view(let subviews):
            _VariadicView.Tree(root: SubviewsRoot(content: self.content), content: subviews)
        }
    }
    
    internal enum Storage {
        case subviewsCollection(SubviewsCollection)
        case view(Subviews)
    }
}

@available(iOS 13.0, *)
internal struct SubviewsRoot<Root: View>: _VariadicView_MultiViewRoot {
    
    internal let content: (SubviewsCollection) -> Root
    
    internal func body(children: _VariadicView.Children) -> some View {
        content(SubviewsCollection(base: children))
    }
}
