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
public struct SwitchToggleStyle : ToggleStyle {
    
    @Environment(\.tintColor)
    internal var controlTint: Color?
    
    internal var tint: Color?
    
    internal var effectiveTint: Color? {
        if let styleTint = self.tint {
            return styleTint
        }
        if let environmentTint = self.controlTint {
            return environmentTint
        }
        return nil
    }
    
    public init() {}

    @available(iOS, deprecated: 100000.0, message: "Use ``View/tint(_)`` instead.")
    @available(macOS, deprecated: 100000.0, message: "Use ``View/tint(_)`` instead.")
    @available(tvOS, unavailable)
    @available(watchOS, deprecated: 100000.0, message: "Use ``View/tint(_)`` instead.")
    public init(tint: Color) {
        self.tint = tint
    }

    /// Creates a view representing the body of a toggle.
    ///
    /// The system calls this method for each ``Toggle`` instance in a view
    /// hierarchy where this style is the current toggle style.
    ///
    /// - Parameter configuration: The properties of the toggle, such as its
    ///   label and its “on” state.
    
    public func makeBody(configuration: SwitchToggleStyle.Configuration) -> some View {
        
        let labeledViewContent = Switch(isOn: configuration.$isOn, tint: self.effectiveTint)
            .fixedSize()
        
        let labeledView = LabeledView(label: configuration.label, content: labeledViewContent)
            // .modifier(_AccessibilityCombineLabelsModifier())
        
        return labeledView
        
    }
}
