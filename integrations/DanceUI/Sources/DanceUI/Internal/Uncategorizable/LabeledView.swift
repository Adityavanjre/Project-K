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
internal struct LabeledView<A: View, B: View>: View {
    
    internal var label: A

    internal var content: B

    internal var injectedNamespace: Namespace.ID?
    
    @Namespace
    internal var namespace: Namespace.ID
    
    internal init(label: A, content: B) {
        self.label = label
        self.content = content
        self.injectedNamespace = .init(id: 0)
    }
    
    internal var body: some View  {
        ResolvedLabeledView(id: "labeledView",
                            namespace: self.namespaceToUse)
            .viewAlias(LabeledViewLabel.self) {
                self.accessibleLabel
            }
            .viewAlias(LabeledViewContent.self) {
                self.accessibleContent
            }
    }
    
    internal var namespaceToUse: Namespace.ID {
        if let namespaceValue = self.injectedNamespace {
            return namespaceValue
        }
        
        return self.namespace
    }
    
    internal var accessibleLabel: some View {
        self.label
            .accessibilityElement(children: .combine)
            .accessibilityLabeledPair(role: .label, id: "labeledView", in: self.namespaceToUse)
    }
    
    internal var accessibleContent: some View {
        self.content.accessibilityLabeledPair(role: .content, id: "labeledView", in: self.namespaceToUse)
    }
}

@available(iOS 13.0, *)
internal struct LabeledViewLabel : ViewAlias {
    
    internal typealias Body = Never
    
}

@available(iOS 13.0, *)
internal struct LabeledViewContent : ViewAlias {
    
    internal typealias Body = Never
    
}
