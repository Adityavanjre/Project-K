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
internal struct DefaultListLabeledViewStyle: LabeledViewStyle {
    
    internal static var combineAccessibility: Bool?
    
    internal struct Body: View {
        
        internal var configuration: LabeledView<LabeledViewLabel, LabeledViewContent>
        
        internal var body: some View {
            
            let spacingLayout = SpacingLayout(spacing: .zeroText)
            
            HStack {
                self.configuration.label
                
                Spacer()
                    .layoutPriority(-1)
                
                self.configuration.content
                    .defaultForegroundColor(Color.secondary)
            }
            .modifier(spacingLayout)
        }
    }
    
    internal func body(configuration: LabeledView<LabeledViewLabel, LabeledViewContent>) -> Body {
        Body(configuration: configuration)
    }
}
