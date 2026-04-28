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
import UIKit

@available(iOS 13.0, *)
internal enum CustomDatePickerStyle : Int {
    
    
    /// Automatically pick the best style available for the current platform & mode.
    case automatic = 0

    /// Use the wheels (UIPickerView) style. Editing occurs inline.
    case wheels = 1

    /// Use a compact style for the date picker. Editing occurs in an overlay.
    case compact = 2

    /// Use a style for the date picker that allows editing in place.
    case inline = 3
}

@available(iOS 13.0, *)
extension CustomDatePickerStyle {
    
    @available(iOS 13.4, *)
    fileprivate func uiStyle() -> UIDatePickerStyle {
        UIDatePickerStyle(rawValue: self.rawValue) ?? .automatic
    }
}

@available(iOS 13.0, *)
internal struct UIKitDatePicker : View {
    
    /*
    typealias Body =
    ModifiedContent<
        LabeledView<
            _DatePickerStyleLabel,
            UIKitDatePickerRepresentable
        >,
        (AccessibilitySeparateLabelAndContentModifier in $b02750)
    >
    */
    
    internal let configuration: DatePicker<_DatePickerStyleLabel>

    internal let style: CustomDatePickerStyle

    @Environment(\.locale)
    internal var locale: Locale

    @Environment(\.calendar)
    internal var calendar: Calendar

    @Environment(\.timeZone)
    internal var timeZone: TimeZone
    
    internal var body: some View {
        LabeledView(label: configuration.label,
                    content: UIKitDatePickerRepresentable(configuration: configuration,
                                                          locale: locale,
                                                          calendar: calendar,
                                                          timeZone: timeZone,
                                                          style: style))
    }

}

@available(iOS 13.0, *)
private final class DanceUIDatePicker: UIDatePicker {

    @objc
    fileprivate override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    @objc
    fileprivate required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc
    fileprivate override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else {
            return
        }
        if let container = self.parentPassingFilter({ view in
            return view is PlatformLayoutContainer
        }) as? PlatformLayoutContainer {
            container.enqueueLayoutInvalidation()
        }
    }
}

@available(iOS 13.0, *)
extension UIView {
    internal func parentPassingFilter(_ action: (UIView) -> Bool) -> UIView? {
        if !action(self) {
            return superview?.parentPassingFilter(action)
        }
        return self
    }
}

@available(iOS 13.0, *)
fileprivate struct UIKitDatePickerRepresentable : UIViewRepresentable {
    
    fileprivate typealias UIViewType = UIDatePicker

    fileprivate let configuration: DatePicker<_DatePickerStyleLabel>

    fileprivate let locale: Locale

    fileprivate let calendar: Calendar

    fileprivate let timeZone: TimeZone

    fileprivate let style: CustomDatePickerStyle

    fileprivate func makeUIView(context: Context) -> UIDatePicker {
        let picker = DanceUIDatePicker()
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(datePicker:)), for: .valueChanged)
        return picker
    }
    
    fileprivate func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.date = configuration.selection.wrappedValue
        uiView.minimumDate = configuration.minimumDate
        uiView.maximumDate = configuration.maximumDate
        uiView.locale = locale
        uiView.calendar = calendar
        uiView.timeZone = timeZone
        if #available(iOS 13.4, *) {
            if style == .inline {
                if #available(iOS 14.0, *) {
                    uiView.preferredDatePickerStyle = .inline
                }
            } else {
                uiView.preferredDatePickerStyle = style.uiStyle()
            }
        }
        uiView.datePickerMode = .init(configuration.displayedComponents)
        context.coordinator.configuration = configuration
    }

    fileprivate func makeCoordinator() -> Coordinator {
        Coordinator(configuration: configuration)
    }
    
    fileprivate func _overrideSizeThatFits(_ size: inout CGSize, in proposedSize: _ProposedSize, uiView: UIDatePicker) {
        guard style == .compact || style == .inline else {
            return
        }
        let compressedSize = uiView.sizeThatFits(UIView.layoutFittingCompressedSize)
        size.height = compressedSize.height
        if style == .compact {
            size.width = compressedSize.width
        }
    }
    
    fileprivate func _overrideLayoutTraits(_ layoutTraits: inout _LayoutTraits, for uiView: UIDatePicker) {
        guard style == .inline else {
            return
        }
        let width = layoutTraits.width

        let maxWidth = _LayoutTraits.Dimension(min: 0, ideal: width.max, max: width.max)

        layoutTraits.width = maxWidth

        let flexibleWidth = _LayoutTraits.Dimension(min: 0, ideal: width.ideal, max: .infinity)

        layoutTraits.width = flexibleWidth
    }
    
    fileprivate final class Coordinator: PlatformViewCoordinator {
        
        fileprivate var configuration: DatePicker<_DatePickerStyleLabel>
        
        fileprivate init(configuration: DatePicker<_DatePickerStyleLabel>) {
            self.configuration = configuration
            super.init()
        }
        
        @objc
        fileprivate override init() {
            _danceuiFatalError("init() has not been implemented")
        }
        
        @objc
        fileprivate func dateChanged(datePicker: UIDatePicker) {
            var date = datePicker.date
            if let minimumDate = configuration.minimumDate {
                date = date >= minimumDate ? date : minimumDate
            }
            if let maximumDate = configuration.maximumDate {
                date = date < maximumDate ? date : maximumDate
            }
            configuration.selection.wrappedValue = date
        }
    }
}

@available(iOS 13.0, *)
extension UIDatePicker.Mode {
    
    internal init(_ components: DatePickerComponents) {
        if components == .hourAndMinute {
            self = .time
        } else if components == .date {
            self = .date
        } else if components == [.date, .hourAndMinute] {
            self = .dateAndTime
        }
        switch components {
        case .date:
            self = .date
        case .hourAndMinute:
            self = .time
        case [.date, .hourAndMinute]:
            self = .dateAndTime
        default:
            _danceuiFatalError()
        }
    }
}
