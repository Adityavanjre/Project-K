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
fileprivate class AnyStyleBox {
    
    fileprivate func body(configuration: Slider<SliderStyleLabel, SliderStyleValueLabel>) -> AnyView {
        _abstract(self)
    }
    
    // TODO: _notImplemented ResolvedSegmentedControl
}

@available(iOS 13.0, *)
private final class StyleBox<A> : AnyStyleBox where A: SliderStyle {
    
    fileprivate let base: A
    
    fileprivate override func body(configuration: Slider<SliderStyleLabel, SliderStyleValueLabel>) -> AnyView {
        base.body(configuration: configuration).eraseToAnyView()
    }

    fileprivate init(base: A) {
        self.base = base
    }
}

@available(iOS 13.0, *)
internal protocol SliderStyle {
    
    associatedtype Body: View
    
    func body(configuration: Slider<SliderStyleLabel, SliderStyleValueLabel>) -> Body

}

@available(iOS 13.0, *)
internal struct AnySliderStyle : SliderStyle {

    internal typealias Body = AnyView
    
    internal static let `default`: AnySliderStyle = AnySliderStyle(box: StyleBox(base: SystemSliderStyle()))
    
    private let box: AnyStyleBox
    
    internal func body(configuration: Slider<SliderStyleLabel, SliderStyleValueLabel>) -> AnyView {
        box.body(configuration: configuration)
    }
}

@available(iOS 13.0, *)
fileprivate struct SystemSliderStyle : SliderStyle {
    
    fileprivate func body(configuration: Slider<SliderStyleLabel, SliderStyleValueLabel>) -> some View {
        HStack {
            SliderMinimumValueLabel()
            SystemSlider(value: configuration.$value, onEditingChanged: configuration.onEditingChanged)
                .frame(height: 31.0)
            SliderMaximumValueLabel()
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct SystemSlider : UIViewRepresentable {

    fileprivate typealias Body = Swift.Never
    
    fileprivate typealias UIViewType = UISlider
    
    fileprivate typealias Coordinator = DanceUI.Coordinator
    
    fileprivate var value: Binding<Double>

    fileprivate var onEditingChanged: (Bool) -> ()
    
    @Environment(\.tintColor)
    internal var controlTint: Color?

    fileprivate func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.editingEnded(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return slider
    }
    
    fileprivate func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.setValue(Float(value.wrappedValue), animated: context.transaction.animation != nil)
        var resolvedColor: UIColor? = nil
        if let environmentTint = self.controlTint {
            resolvedColor = environmentTint.resolvedUIColor(in: context.environment)
        }
        if let color = uiView.tintColor {
            if resolvedColor != nil && resolvedColor != color {
                uiView.tintColor = resolvedColor
            }
        }
        context.coordinator.configuration = self
    }
    
    fileprivate func makeCoordinator() -> Coordinator {
        Coordinator(configuration: self)
    }
}

@available(iOS 13.0, *)
private final class Coordinator: PlatformViewCoordinator {
    
    fileprivate var configuration: SystemSlider
    
    fileprivate var isUpdating: Bool
    
    fileprivate override init() {
        _danceuiFatalError()
    }
    
    fileprivate init(configuration: SystemSlider) {
        self.isUpdating = false
        self.configuration = configuration
    }
    
    @objc
    fileprivate func editingEnded(_ slider: UISlider) {
        isUpdating = false
        Update.perform {
            configuration.onEditingChanged(false)
        }
    }
    
    @objc
    fileprivate func valueChanged(_ slider: UISlider) {
        if !isUpdating {
            isUpdating = true
            Update.perform {
                configuration.onEditingChanged(true)
            }
        }
        configuration.value.wrappedValue = Double(slider.value)
        slider.value = Float(configuration.value.wrappedValue)
    }
}


