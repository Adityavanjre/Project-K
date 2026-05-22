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

internal import DanceUIGraph

@available(iOS 13.0, *)
extension View {
    
    /// Sets the style for buttons within this view to a button style with a
    /// custom appearance and custom interaction behavior.
    ///
    /// Use this modifier to set a specific style for button instances
    /// within a view:
    ///
    ///     HStack {
    ///         Button("Sign In", action: signIn)
    ///         Button("Register", action: register)
    ///     }
    ///     .buttonStyle(.bordered)
    ///
    public func buttonStyle<PrimitiveStyle: PrimitiveButtonStyle>(_ style: PrimitiveStyle) -> some View {
        modifier(ButtonStyleModifier(style: style))
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Sets the style for buttons within this view to a button style with a
    /// custom appearance and standard interaction behavior.
    ///
    /// Use this modifier to set a specific style for all button instances
    /// within a view:
    ///
    ///     HStack {
    ///         Button("Sign In", action: signIn)
    ///         Button("Register", action: register)
    ///     }
    ///     .buttonStyle(.bordered)
    ///
    /// You can also use this modifier to set the style for controls with a button
    /// style through composition:
    ///
    ///     VStack {
    ///         Menu("Terms and Conditions") {
    ///             Button("Open in Preview", action: openInPreview)
    ///             Button("Save as PDF", action: saveAsPDF)
    ///         }
    ///         Toggle("Remember Password", isOn: $isToggleOn)
    ///         Toggle("Flag", isOn: $flagged)
    ///         Button("Sign In", action: signIn)
    ///     }
    ///     .menuStyle(.button)
    ///     .toggleStyle(.button)
    ///     .buttonStyle(.bordered)
    ///
    /// In this example, `.menuStyle(.button)` says that the Terms and
    /// Conditions menu renders as a button, while
    /// `.toggleStyle(.button)` says that the two toggles also render as
    /// buttons. Finally, `.buttonStyle(.bordered)` says that the menu,
    /// both toggles, and the Sign In button all render with the
    /// bordered button style.```
    public func buttonStyle<Style: ButtonStyle>(_ style: Style) -> some View {
        modifier(ButtonStyleModifier(style: WrappedButtonStyle(style: style)))
    }
    
}

@available(iOS 13.0, *)
fileprivate struct WrappedButtonStyle<S: ButtonStyle>: PrimitiveButtonStyle {
    
    internal let style: S
    
    internal func makeBody(configuration: Configuration) -> some View {
        ButtonBehavior(
            action: configuration.action,
            content: { isPressed in
                ResolvedButtonStyleBody(style: style, configuration: ButtonStyleConfiguration(isPressed: isPressed, role: configuration.role))
            },
            state: (false, false),
            name: configuration.name
        )
    }
    
}

@available(iOS 13.0, *)
internal struct ResolvedButtonStyleBody<Style: ButtonStyle>: PrimitiveView {
    
    internal var style: Style
    
    internal var configuration: ButtonStyleConfiguration
    
    internal static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        let fileds = DynamicPropertyCache.fields(of: Style.self)
        var bodyInputs = inputs
        
        let (styleBody, styleBuffer) = bodyInputs.withMutableGraphInputs { bodyGraphInputs in
            makeStyleBody(view: view, inputs: &bodyGraphInputs, fields: fileds)
        }
        
        
        let outupts = Style.Body.makeDebuggableView(value: styleBody, inputs: bodyInputs)
        
        if let buffer = styleBuffer {
            buffer.traceMountedProperties(to: view, fields: fileds)
        }
        
        return outupts
    }
    
    internal static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs { // BDCOV_EXCL_BLOCK dithering
        var newInputs = inputs
        
        let styleFields = DynamicPropertyCache.fields(of: Style.self)
        
        let (styleBody, styleBuffer) = newInputs.withMutableGraphInputs { base in
            makeStyleBody(view: view, inputs: &base, fields: styleFields)
        }
        
        
        let outputs = Style.Body._makeViewList(view: styleBody, inputs: newInputs)
        
        if let buffer = styleBuffer {
            buffer.traceMountedProperties(to: view, fields: styleFields)
        }
        
        return outputs
    }
    
    private static func makeStyleBody(view: _GraphValue<Self>,
                                      inputs: inout _GraphInputs,
                                      fields: DynamicPropertyCache.Fields) -> (_GraphValue<Style.Body>, _DynamicPropertyBuffer?) {
        
        let kind = DGTypeID(Style.self).kind
        
        guard kind.isOfValueTypes else {
            _danceuiFatalError("\(_typeName(Style.self)) is a class.")
        }
        
        _ = GraphHost.currentHost
        
        let styleBodyAccessor = StyleBodyAccessor(view: view.value)
        
        return styleBodyAccessor.makeBody(container: view[\.style], inputs: &inputs, fields: fields)
    }
    
    fileprivate struct StyleBodyAccessor: BodyAccessor {
        
        fileprivate typealias Container = Style
        
        fileprivate typealias Body = Style.Body
        
        @Attribute
        fileprivate var view: ResolvedButtonStyleBody<Style>
        
        fileprivate func updateBody(of container: Container, changed: Bool) {
            let (view, isViewChanged) = $view.changedValue()
            guard changed || isViewChanged else {
                return
            }
            
            setBody {
                container.makeBody(configuration: view.configuration)
            }
        }
    }
    
}
