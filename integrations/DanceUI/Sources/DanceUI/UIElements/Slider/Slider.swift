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

/// A control for selecting a value from a bounded linear range of values.
///
/// A slider consists of a "thumb" image that the user moves between two
/// extremes of a linear "track". The ends of the track represent the minimum
/// and maximum possible values. As the user moves the thumb, the slider
/// updates its bound value.
///
/// The following example shows a slider bound to the value `speed`. As the
/// slider updates this value, a bound ``Text`` view shows the value updating.
/// The `onEditingChanged` closure passed to the slider receives callbacks when
/// the user drags the slider. The example uses this to change the
/// color of the value text.
///
///     @State private var speed = 50.0
///     @State private var isEditing = false
///
///     var body: some View {
///         VStack {
///             Slider(
///                 value: $speed,
///                 in: 0...100,
///                 onEditingChanged: { editing in
///                     isEditing = editing
///                 }
///             )
///             Text("\(speed)")
///                 .foregroundColor(isEditing ? .red : .blue)
///         }
///     }
///
/// ![An unlabeled slider, with its thumb about one third of the way from the
/// minimum extreme. Below, a blue label displays the value
/// 33.045977.](DanceUI-Slider-simple.png)
///
/// You can also use a `step` parameter to provide incremental steps along the
/// path of the slider. For example, if you have a slider with a range of `0` to
/// `100`, and you set the `step` value to `5`, the slider's increments would be
/// `0`, `5`, `10`, and so on. The following example shows this approach, and
/// also adds optional minimum and maximum value labels.
///
///     @State private var speed = 50.0
///     @State private var isEditing = false
///
///     var body: some View {
///         Slider(
///             value: $speed,
///             in: 0...100,
///             step: 5
///         ) {
///             Text("Speed")
///         } minimumValueLabel: {
///             Text("0")
///         } maximumValueLabel: {
///             Text("100")
///         } onEditingChanged: { editing in
///             isEditing = editing
///         }
///         Text("\(speed)")
///             .foregroundColor(isEditing ? .red : .blue)
///     }
///
/// ![A slider with labels show minimum and maximum values of 0 and 100,
/// respectively, with its thumb most of the way to the maximum extreme. Below,
/// a blue label displays the value
/// 85.000000.](DanceUI-Slider-withStepAndLabels.png)
///
/// The slider also uses the `step` to increase or decrease the value when a
/// VoiceOver user adjusts the slider with voice commands.
@available(iOS 13.0, *)
public struct Slider<Label, ValueLabel> : View where Label : View, ValueLabel : View {
    
    @Binding
    internal var value: Double
    
    internal var onEditingChanged: (Bool) -> ()

    internal let skipDistance: Double

    internal let discreteValueCount: Int

    internal var minimumValueLabel: ValueLabel
    
    internal var maximumValueLabel: ValueLabel

    internal var hasCustomMinMaxValueLabels: Bool

    internal var label: Label

    @Environment
    internal var style: AnySliderStyle
    
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that DanceUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    public var body: some View {
        style.body(configuration: Slider<SliderStyleLabel, SliderStyleValueLabel>(self))
            .viewAlias(SliderStyleLabel.self) {
                label
            }
            .viewAlias(SliderMinimumValueLabel.self) {
                minimumValueLabel
            }
            .viewAlias(SliderMaximumValueLabel.self) {
                maximumValueLabel
            }
//            .accessibilityAdjustableAction() { _ in }
//            .accessibilityAdjustableAction() { _ in }
    }
}

@available(iOS 13.0, *)
internal struct SliderStyleLabel : ViewAlias {
    
    internal typealias Body = Never
}

@available(iOS 13.0, *)
internal struct SliderStyleValueLabel : ViewAlias {
    
    internal typealias Body = Never
}

@available(iOS 13.0, *)
internal struct SliderMinimumValueLabel : ViewAlias {
    
    internal typealias Body = Never
}

@available(iOS 13.0, *)
internal struct SliderMaximumValueLabel : ViewAlias {
    
    internal typealias Body = Never
}

@available(iOS 13.0, *)
extension Slider {
    
    /// Creates a slider to select a value from a given range, which displays
    /// the provided labels.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of the valid values. Defaults to `0...1`.
    ///   - label: A `View` that describes the purpose of the instance. Not all
    ///     slider styles show the label, but even in those cases, DanceUI
    ///     uses the label for accessibility. For example, VoiceOver uses the
    ///     label to identify the purpose of the slider.
    ///   - minimumValueLabel: A view that describes `bounds.lowerBound`.
    ///   - maximumValueLabel: A view that describes `bounds.lowerBound`.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    ///
    /// The `value` of the created instance is equal to the position of
    /// the given value within `bounds`, mapped into `0...1`.
    ///
    /// The slider calls `onEditingChanged` when editing begins and ends. For
    /// example, on iOS, editing begins when the user starts to drag the thumb
    /// along the slider's track.
    public init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0...1, @ViewBuilder label: () -> Label, @ViewBuilder minimumValueLabel: () -> ValueLabel, @ViewBuilder maximumValueLabel: () -> ValueLabel, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
        
        self.init(
            value: value.projecting(Normalizing.init(min: bounds.lowerBound, max: bounds.upperBound)),
            skipDistance: nil,
            onEditingChanged: onEditingChanged,
            minimumValueLabel: minimumValueLabel(),
            maximumValueLabel: maximumValueLabel(),
            customMinMaxValueLabels: true,
            label: label
        )
    }
    
    /// Creates a slider to select a value from a given range, subject to a
    /// step increment, which displays the provided labels.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of the valid values. Defaults to `0...1`.
    ///   - step: The distance between each valid value.
    ///   - label: A `View` that describes the purpose of the instance. Not all
    ///     slider styles show the label, but even in those cases, DanceUI
    ///     uses the label for accessibility. For example, VoiceOver uses the
    ///     label to identify the purpose of the slider.
    ///   - minimumValueLabel: A view that describes `bounds.lowerBound`.
    ///   - maximumValueLabel: A view that describes `bounds.lowerBound`.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    ///
    /// The `value` of the created instance is equal to the position of
    /// the given value within `bounds`, mapped into `0...1`.
    ///
    /// The slider calls `onEditingChanged` when editing begins and ends. For
    /// example, on iOS, editing begins when the user starts to drag the thumb
    /// along the slider's track.
    public init<V>(value: Binding<V>, in bounds: ClosedRange<V>, step: V.Stride = 1, @ViewBuilder label: () -> Label, @ViewBuilder minimumValueLabel: () -> ValueLabel, @ViewBuilder maximumValueLabel: () -> ValueLabel, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
        let normalizing = Normalizing.init(min: bounds.lowerBound, max: bounds.upperBound, stride: step)
        self.init(
            value: value.projecting(normalizing),
            skipDistance: step / normalizing.length,
            onEditingChanged: onEditingChanged,
            minimumValueLabel: minimumValueLabel(),
            maximumValueLabel: maximumValueLabel(),
            customMinMaxValueLabels: true,
            label: label
        )
    }
}

@available(iOS 13.0, *)
extension Slider where ValueLabel == EmptyView {
    
    /// Creates a slider to select a value from a given range, which displays
    /// the provided label.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of the valid values. Defaults to `0...1`.
    ///   - label: A `View` that describes the purpose of the instance. Not all
    ///     slider styles show the label, but even in those cases, DanceUI
    ///     uses the label for accessibility. For example, VoiceOver uses the
    ///     label to identify the purpose of the slider.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    ///
    /// The `value` of the created instance is equal to the position of
    /// the given value within `bounds`, mapped into `0...1`.
    ///
    /// The slider calls `onEditingChanged` when editing begins and ends. For
    /// example, on iOS, editing begins when the user starts to drag the thumb
    /// along the slider's track.
    public init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0...1, @ViewBuilder label: () -> Label, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
        
        self.init(
            value: value.projecting(Normalizing.init(min: bounds.lowerBound, max: bounds.upperBound)),
            skipDistance: nil,
            onEditingChanged: onEditingChanged,
            minimumValueLabel: EmptyView(),
            maximumValueLabel: EmptyView(),
            customMinMaxValueLabels: false,
            label: label
        )
    }

    /// Creates a slider to select a value from a given range, subject to a
    /// step increment, which displays the provided label.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of the valid values. Defaults to `0...1`.
    ///   - step: The distance between each valid value.
    ///   - label: A `View` that describes the purpose of the instance. Not all
    ///     slider styles show the label, but even in those cases, DanceUI
    ///     uses the label for accessibility. For example, VoiceOver uses the
    ///     label to identify the purpose of the slider.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    ///
    /// The `value` of the created instance is equal to the position of
    /// the given value within `bounds`, mapped into `0...1`.
    ///
    /// The slider calls `onEditingChanged` when editing begins and ends. For
    /// example, on iOS, editing begins when the user starts to drag the thumb
    /// along the slider's track.
    public init<V>(value: Binding<V>, in bounds: ClosedRange<V>, step: V.Stride = 1, @ViewBuilder label: () -> Label, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
        
        let normalizing = Normalizing.init(min: bounds.lowerBound, max: bounds.upperBound, stride: step)
        self.init(
            value: value.projecting(normalizing),
            skipDistance: step / normalizing.length,
            onEditingChanged: onEditingChanged,
            minimumValueLabel: EmptyView(),
            maximumValueLabel: EmptyView(),
            customMinMaxValueLabels: false,
            label: label
        )
    }
}

@available(iOS 13.0, *)
extension Slider where Label == EmptyView, ValueLabel == EmptyView {

    /// Creates a slider to select a value from a given range.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of the valid values. Defaults to `0...1`.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    ///
    /// The `value` of the created instance is equal to the position of
    /// the given value within `bounds`, mapped into `0...1`.
    ///
    /// The slider calls `onEditingChanged` when editing begins and ends. For
    /// example, on iOS, editing begins when the user starts to drag the thumb
    /// along the slider's track.
    public init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0...1, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
        
        self.init(
            value: value.projecting(Normalizing.init(min: bounds.lowerBound, max: bounds.upperBound)),
            skipDistance: nil,
            onEditingChanged: onEditingChanged,
            minimumValueLabel: EmptyView(),
            maximumValueLabel: EmptyView(),
            customMinMaxValueLabels: false) {
            EmptyView()
        }
    }

    /// Creates a slider to select a value from a given range, subject to a
    /// step increment.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of the valid values. Defaults to `0...1`.
    ///   - step: The distance between each valid value.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    ///
    /// The `value` of the created instance is equal to the position of
    /// the given value within `bounds`, mapped into `0...1`.
    ///
    /// The slider calls `onEditingChanged` when editing begins and ends. For
    /// example, on iOS, editing begins when the user starts to drag the thumb
    /// along the slider's track.
    public init<V>(value: Binding<V>, in bounds: ClosedRange<V>, step: V.Stride = 1, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
        
        let normalizing = Normalizing.init(min: bounds.lowerBound, max: bounds.upperBound, stride: step)
        
        self.init(
            value: value.projecting(normalizing),
            skipDistance: step / normalizing.length,
            onEditingChanged: onEditingChanged,
            minimumValueLabel: EmptyView(),
            maximumValueLabel: EmptyView(),
            customMinMaxValueLabels: false) {
            EmptyView()
        }
    }
}

@available(iOS 13.0, *)
extension Slider {

    private init<A : View, B : View>(_ slider: Slider<A, B>) where Label == SliderStyleLabel, ValueLabel == SliderStyleValueLabel {
        
        self.init(
            value: slider.$value,
            onEditingChanged: slider.onEditingChanged,
            skipDistance: slider.skipDistance,
            discreteValueCount: slider.discreteValueCount,
            minimumValueLabel: SliderStyleValueLabel(),
            maximumValueLabel: SliderStyleValueLabel(),
            hasCustomMinMaxValueLabels: slider.hasCustomMinMaxValueLabels,
            label: SliderStyleLabel(),
            style: Environment(\.sliderStyle))
    }
    
    private init<V>(value: Binding<V>, skipDistance: V?, onEditingChanged: @escaping (Bool) -> (), minimumValueLabel: ValueLabel, maximumValueLabel: ValueLabel, customMinMaxValueLabels: Bool, label: () -> Label) where V: BinaryFloatingPoint {
        
        let discreteValueCount = skipDistance != nil ? Int(1.0 / Double(skipDistance!)) + 1 : 0
        let distance: Double = skipDistance.map { d in Double(d) } ?? 0.1
        
        self.init(
            value: value.projecting(Clamping<V>()),
            onEditingChanged: onEditingChanged,
            skipDistance: distance,
            discreteValueCount: discreteValueCount,
            minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel,
            hasCustomMinMaxValueLabels: customMinMaxValueLabels,
            label: label(),
            style: Environment(\.sliderStyle))
    }
}

@available(iOS 13.0, *)
fileprivate struct Clamping<A: BinaryFloatingPoint> : Projection, Hashable, Equatable  {
    
    fileprivate typealias Base = A
    
    fileprivate typealias Projected = Double
    
    fileprivate func get(base: A) -> Double {
        min(max(Double.init(base), 0.0), 1.0)
    }
    
    fileprivate func set(base: inout A, newValue: Double) {
        base = A(min(max(newValue, 0.0), 1.0))
    }
}

@available(iOS 13.0, *)
fileprivate struct Normalizing<A: Strideable> : Projection, Hashable, Equatable where A.Stride: FloatingPoint, A: Hashable {

    fileprivate typealias Base = A

    fileprivate typealias Projected = A.Stride
    
    fileprivate let min: A

    fileprivate let max: A

    fileprivate let stride: A.Stride?

    fileprivate let maxStrides: A.Stride?

    fileprivate let length: A.Stride

    fileprivate func get(base: A) -> A.Stride {
        min.distance(to: base) / length
    }
    
    fileprivate func set(base: inout A, newValue: A.Stride) {
        var updateStride: A.Stride
        if let stride1 = stride, let maxStrides1 = maxStrides {
            updateStride = stride1 * (newValue * maxStrides1).rounded(.toNearestOrAwayFromZero)
        } else {
            updateStride = newValue * length
        }
        base = min.advanced(by: updateStride)
    }
    
    fileprivate init(min: A, max: A, stride: A.Stride? = nil) {
        self.min = min
        self.max = max
        self.stride = stride

        var maxStrides: A.Stride
        if let stride1 = stride {
            maxStrides = (min.distance(to: max) / stride1).rounded(.down)
            self.length = stride1 * maxStrides
            _danceuiPrecondition(maxStrides > 0)
            self.maxStrides = maxStrides
        } else {
            self.length = min.distance(to: max)
            self.maxStrides = nil
        }
    }
}

@available(tvOS, unavailable)
@available(iOS 13.0, *)
extension Slider {

    /// Creates a slider to select a value from a given range, which displays
    /// the provided labels.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of the valid values. Defaults to `0...1`.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    ///   - minimumValueLabel: A view that describes `bounds.lowerBound`.
    ///   - maximumValueLabel: A view that describes `bounds.lowerBound`.
    ///   - label: A `View` that describes the purpose of the instance. Not all
    ///     slider styles show the label, but even in those cases, DanceUI
    ///     uses the label for accessibility. For example, VoiceOver uses the
    ///     label to identify the purpose of the slider.
    ///
    /// The `value` of the created instance is equal to the position of
    /// the given value within `bounds`, mapped into `0...1`.
    ///
    /// The slider calls `onEditingChanged` when editing begins and ends. For
    /// example, on iOS, editing begins when the user starts to drag the thumb
    /// along the slider's track.
    @available(tvOS, unavailable)
    @available(iOS, deprecated: 100000.0, renamed: "Slider(value:in:label:minimumValueLabel:maximumValueLabel:onEditingChanged:)")
    @available(macOS, deprecated: 100000.0, renamed: "Slider(value:in:label:minimumValueLabel:maximumValueLabel:onEditingChanged:)")
    @available(watchOS, deprecated: 100000.0, renamed: "Slider(value:in:label:minimumValueLabel:maximumValueLabel:onEditingChanged:)")
    public init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0...1, onEditingChanged: @escaping (Bool) -> Void = { _ in }, minimumValueLabel: ValueLabel, maximumValueLabel: ValueLabel, @ViewBuilder label: () -> Label) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
        self.init(
            value: value.projecting(Normalizing.init(min: bounds.lowerBound, max: bounds.upperBound)),
            skipDistance: nil,
            onEditingChanged: onEditingChanged,
            minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel,
            customMinMaxValueLabels: true,
            label: label
        )
    }

    /// Creates a slider to select a value from a given range, subject to a
    /// step increment, which displays the provided labels.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of the valid values. Defaults to `0...1`.
    ///   - step: The distance between each valid value.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    ///   - minimumValueLabel: A view that describes `bounds.lowerBound`.
    ///   - maximumValueLabel: A view that describes `bounds.lowerBound`.
    ///   - label: A `View` that describes the purpose of the instance. Not all
    ///     slider styles show the label, but even in those cases, DanceUI
    ///     uses the label for accessibility. For example, VoiceOver uses the
    ///     label to identify the purpose of the slider.
    ///
    /// The `value` of the created instance is equal to the position of
    /// the given value within `bounds`, mapped into `0...1`.
    ///
    /// The slider calls `onEditingChanged` when editing begins and ends. For
    /// example, on iOS, editing begins when the user starts to drag the thumb
    /// along the slider's track.
    @available(tvOS, unavailable)
    @available(iOS, deprecated: 100000.0, renamed: "Slider(value:in:step:label:minimumValueLabel:maximumValueLabel:onEditingChanged:)")
    @available(macOS, deprecated: 100000.0, renamed: "Slider(value:in:step:label:minimumValueLabel:maximumValueLabel:onEditingChanged:)")
    @available(watchOS, deprecated: 100000.0, renamed: "Slider(value:in:step:label:minimumValueLabel:maximumValueLabel:onEditingChanged:)")
    public init<V>(value: Binding<V>, in bounds: ClosedRange<V>, step: V.Stride = 1, onEditingChanged: @escaping (Bool) -> Void = { _ in }, minimumValueLabel: ValueLabel, maximumValueLabel: ValueLabel, @ViewBuilder label: () -> Label) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
        let normalizing = Normalizing.init(min: bounds.lowerBound, max: bounds.upperBound, stride: step)
        self.init(
            value: value.projecting(normalizing),
            skipDistance: step / normalizing.length,
            onEditingChanged: onEditingChanged,
            minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel,
            customMinMaxValueLabels: true,
            label: label
        )
    }
}

@available(tvOS, unavailable)
@available(iOS 13.0, *)
extension Slider where ValueLabel == EmptyView {

    /// Creates a slider to select a value from a given range, which displays
    /// the provided label.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of the valid values. Defaults to `0...1`.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    ///   - label: A `View` that describes the purpose of the instance. Not all
    ///     slider styles show the label, but even in those cases, DanceUI
    ///     uses the label for accessibility. For example, VoiceOver uses the
    ///     label to identify the purpose of the slider.
    ///
    /// The `value` of the created instance is equal to the position of
    /// the given value within `bounds`, mapped into `0...1`.
    ///
    /// The slider calls `onEditingChanged` when editing begins and ends. For
    /// example, on iOS, editing begins when the user starts to drag the thumb
    /// along the slider's track.
    @available(tvOS, unavailable)
    @available(iOS, deprecated: 100000.0, renamed: "Slider(value:in:label:onEditingChanged:)")
    @available(macOS, deprecated: 100000.0, renamed: "Slider(value:in:label:onEditingChanged:)")
    @available(watchOS, deprecated: 100000.0, renamed: "Slider(value:in:label:onEditingChanged:)")
    @_disfavoredOverload
    public init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0...1, onEditingChanged: @escaping (Bool) -> Void = { _ in }, @ViewBuilder label: () -> Label) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
        self.init(value: value, in: bounds, label: label, onEditingChanged: onEditingChanged)
    }

    /// Creates a slider to select a value from a given range, subject to a
    /// step increment, which displays the provided label.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of the valid values. Defaults to `0...1`.
    ///   - step: The distance between each valid value.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    ///   - label: A `View` that describes the purpose of the instance. Not all
    ///     slider styles show the label, but even in those cases, DanceUI
    ///     uses the label for accessibility. For example, VoiceOver uses the
    ///     label to identify the purpose of the slider.
    ///
    /// The `value` of the created instance is equal to the position of
    /// the given value within `bounds`, mapped into `0...1`.
    ///
    /// The slider calls `onEditingChanged` when editing begins and ends. For
    /// example, on iOS, editing begins when the user starts to drag the thumb
    /// along the slider's track.
    @available(tvOS, unavailable)
    @available(iOS, deprecated: 100000.0, renamed: "Slider(value:in:step:label:onEditingChanged:)")
    @available(macOS, deprecated: 100000.0, renamed: "Slider(value:in:step:label:onEditingChanged:)")
    @available(watchOS, deprecated: 100000.0, renamed: "Slider(value:in:step:label:onEditingChanged:)")
    @_disfavoredOverload
    public init<V>(value: Binding<V>, in bounds: ClosedRange<V>, step: V.Stride = 1, onEditingChanged: @escaping (Bool) -> Void = { _ in }, @ViewBuilder label: () -> Label) where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
        self.init(value: value,
                  in: bounds,
                  step: step,
                  label: label,
                  onEditingChanged: onEditingChanged)
    }
}
