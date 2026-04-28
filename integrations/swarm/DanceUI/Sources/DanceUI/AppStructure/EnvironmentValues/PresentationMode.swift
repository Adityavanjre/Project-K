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

/// An indication whether a view is currently presented by another view.
@available(iOS, deprecated: 100000.0, message: "Use EnvironmentValues.isPresented or EnvironmentValues.dismiss")
@available(macOS, deprecated: 100000.0, message: "Use EnvironmentValues.isPresented or EnvironmentValues.dismiss")
@available(tvOS, deprecated: 100000.0, message: "Use EnvironmentValues.isPresented or EnvironmentValues.dismiss")
@available(watchOS, deprecated: 100000.0, message: "Use EnvironmentValues.isPresented or EnvironmentValues.dismiss")
@available(iOS 13.0, *)
public struct PresentationMode {

    /// Indicates whether a view is currently presented.
    public internal(set) var isPresented: Bool

    /// Dismisses the view if it is currently presented.
    ///
    /// If `isPresented` is false, `dismiss()` is a no-op.
    public mutating func dismiss() {
        self.isPresented = false
    }

}

/// An action that dismisses a presentation.
///
/// Use the ``EnvironmentValues/dismiss`` environment value to get the instance
/// of this structure for a given ``Environment``. Then call the instance
/// to perform the dismissal. You call the instance directly because
/// it defines a ``DismissAction/callAsFunction()``
/// method that Swift calls when you call the instance.
///
/// For example, you can create a button that calls the ``DismissAction``:
///
///     private struct SheetContents: View {
///         @Environment(\.dismiss) private var dismiss
///
///         var body: some View {
///             Button("Done") {
///                 dismiss()
///             }
///         }
///     }
///
/// If you present the `SheetContents` view in a sheet, the user can dismiss
/// the sheet by tapping or clicking the sheet's button:
///
///     private struct DetailView: View {
///         @State private var isSheetPresented = false
///
///         var body: some View {
///             Button("Show Sheet") {
///                 isSheetPresented = true
///             }
///             .sheet(isPresented: $isSheetPresented) {
///                 SheetContents()
///             }
///         }
///     }
///
/// Be sure that you define the action in the appropriate environment.
/// For example, don't reorganize the `DetailView` in the example above
/// so that it creates the `dismiss` property and calls it from the
/// ``View/sheet(item:onDismiss:content:)`` view modifier's `content`
/// closure:
///
///     private struct DetailView: View {
///         @State private var isSheetPresented = false
///         @Environment(\.dismiss) private var dismiss // Applies to DetailView.
///
///         var body: some View {
///             Button("Show Sheet") {
///                 isSheetPresented = true
///             }
///             .sheet(isPresented: $isSheetPresented) {
///                 Button("Done") {
///                     dismiss() // Fails to dismiss the sheet.
///                 }
///             }
///         }
///     }
///
/// If you do this, the sheet fails to dismiss because the action applies
/// to the environment where you declared it, which is that of the detail
/// view, rather than the sheet. In fact, if you've presented the detail
/// view in a ``NavigationView``, the dismissal pops the detail view
/// from the navigation stack.
///
/// The dismiss action has no effect on a view that isn't currently
/// presented. If you need to query whether DanceUI is currently presenting
/// a view, read the ``EnvironmentValues/isPresented`` environment value.
@available(iOS 13.0, *)
public struct DismissAction {
    
    internal var action: () -> ()
    
    /// Dismisses the view if it is currently presented.
    ///
    /// Don't call this method directly. DanceUI calls it for you when you
    /// call the ``DismissAction`` structure that you get from the
    /// ``Environment``:
    ///
    ///     private struct SheetContents: View {
    ///         @Environment(\.dismiss) private var dismiss
    ///
    ///         var body: some View {
    ///             Button("Done") {
    ///                 dismiss() // Implicitly calls dismiss.callAsFunction()
    ///             }
    ///         }
    ///     }
    ///
    /// For information about how Swift uses the `callAsFunction()` method to
    /// simplify call site syntax, see
    /// [Methods with Special Names](https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID622)
    /// in *The Swift Programming Language*.
    public func callAsFunction() {
        action()
    }
    
}

@available(iOS 13.0, *)
extension PresentationMode {
    
    internal struct FromIsPresented: Projection {
        
        internal typealias Base = Bool
        
        internal typealias Projected = PresentationMode
        
        internal func get(base: Bool) -> PresentationMode {
            return PresentationMode(isPresented: base)
        }
        
        internal func set(base: inout Bool, newValue: PresentationMode) {
            base = newValue.isPresented
        }
        
    }

    internal struct FromItem<A>: Projection {

        internal typealias Base = A?
        
        internal typealias Projected = PresentationMode
        
        internal func get(base: A?) -> PresentationMode {
            let isPresented = (base == nil)
            return PresentationMode(isPresented: isPresented)
        }
        
        internal func set(base: inout A?, newValue: PresentationMode) {
            if !newValue.isPresented {
                base = nil
            }
        }
        
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// A binding to the current presentation mode of the view associated with
    /// this environment.
    public internal(set) var presentationMode: Binding<PresentationMode> {
        get {
            self[PresentationModeKey.self]
        }
        set {
            self[PresentationModeKey.self] = newValue
        }
    }

    fileprivate struct PresentationModeKey: EnvironmentKey {

        internal typealias Value = Binding<PresentationMode>
        
        internal static var defaultValue: Binding<PresentationMode> {
            let value = PresentationMode(isPresented: false)
            return Binding.constant(value)
        }
    }
    
    /// A Boolean value that indicates whether the view associated with this
    /// environment is currently presented.
    ///
    /// You can read this value like any of the other ``EnvironmentValues``
    /// by creating a property with the ``Environment`` property wrapper:
    ///
    ///     @Environment(\.isPresented) private var isPresented
    ///
    /// Read the value inside a view if you need to know when DanceUI
    /// presents that view. For example, you can take an action when DanceUI
    /// presents a view by using the ``View/onChange(of:perform:)``
    /// modifier:
    ///
    ///     .onChange(of: isPresented) { isPresented in
    ///         if isPresented {
    ///             // Do something when first presented.
    ///         }
    ///     }
    ///
    /// This behaves differently than ``View/onAppear(perform:)``, which
    /// DanceUI can call more than once for a given presentation, like
    /// when you navigate back to a view that's already in the
    /// navigation hierarchy.
    ///
    /// To dismiss the currently presented view, use
    /// ``EnvironmentValues/dismiss``.
    public var isPresented: Bool {
        self.presentationMode.wrappedValue.isPresented
    }
    
    /// An action that dismisses the current presentation.
    ///
    /// Use this environment value to get the ``DismissAction`` instance
    /// for the current ``Environment``. Then call the instance
    /// to perform the dismissal. You call the instance directly because
    /// it defines a ``DismissAction/callAsFunction()``
    /// method that Swift calls when you call the instance.
    ///
    /// For example, you can create a button that calls the ``DismissAction``:
    ///
    ///     private struct SheetContents: View {
    ///         @Environment(\.dismiss) private var dismiss
    ///
    ///         var body: some View {
    ///             Button("Done") {
    ///                 dismiss()
    ///             }
    ///         }
    ///     }
    ///
    /// If you present the `SheetContents` view in a sheet, the user can dismiss
    /// the sheet by tapping or clicking the sheet's button:
    ///
    ///     private struct DetailView: View {
    ///         @State private var isSheetPresented = false
    ///
    ///         var body: some View {
    ///             Button("Show Sheet") {
    ///                 isSheetPresented = true
    ///             }
    ///             .sheet(isPresented: $isSheetPresented) {
    ///                 SheetContents()
    ///             }
    ///         }
    ///     }
    ///
    /// Be sure that you define the action in the appropriate environment.
    /// For example, don't reorganize the `DetailView` in the example above
    /// so that it creates the `dismiss` property and calls it from the
    /// ``View/sheet(item:onDismiss:content:)`` view modifier's `content`
    /// closure:
    ///
    ///     private struct DetailView: View {
    ///         @State private var isSheetPresented = false
    ///         @Environment(\.dismiss) private var dismiss // Applies to DetailView.
    ///
    ///         var body: some View {
    ///             Button("Show Sheet") {
    ///                 isSheetPresented = true
    ///             }
    ///             .sheet(isPresented: $isSheetPresented) {
    ///                 Button("Done") {
    ///                     dismiss() // Fails to dismiss the sheet.
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// If you do this, the sheet fails to dismiss because the action applies
    /// to the environment where you declared it, which is that of the detail
    /// view, rather than the sheet. In fact, if you've presented the detail
    /// view in a ``NavigationView``, the dismissal pops the detail view
    /// the navigation stack.
    ///
    /// The dismiss action has no effect on a view that isn't currently
    /// presented. If you need to query whether DanceUI is currently presenting
    /// a view, read the ``EnvironmentValues/isPresented`` environment value.
    public var dismiss: DismissAction {
        return DismissAction {
            self.presentationMode.wrappedValue.isPresented = false
        }
    }
    
}
