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
internal struct DefaultLabeledViewStyle: LabeledViewStyle {
    
    internal typealias Body = DefaultLabeledViewStyle._Body
    
    internal static var combineAccessibility: Bool?
    
    internal struct _Body: View {
        
        internal var configuration: LabeledView<LabeledViewLabel, LabeledViewContent>
        
        internal var body: some View {
            
            let labelViewStyleModifier = configuration.content.modifier(_LabeledViewStyleModifier(style: DefaultLabeledViewStyle()))
            
            let configurableContentModifier = configuration.viewAlias(LabeledViewContent.self) {
                labelViewStyleModifier
            }
                        
            return configurableContentModifier.modifier(_LabeledViewStyleModifier(style: DefaultListLabeledViewStyle()))
        }
    }
    
    internal func body(configuration: LabeledView<LabeledViewLabel, LabeledViewContent>) -> Body {
        _Body(configuration: configuration)
    }
    
}
