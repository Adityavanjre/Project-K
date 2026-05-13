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

///
////// A representation of an alert presentation.
///
/// Use an alert when you want the user to act in response to the state of the
/// app or the system. If you want the user to make a choice in response to
/// their own action, use an ``ActionSheet`` instead.
///
/// You show an alert by using the ``View/alert(isPresented:content:)`` view
/// modifier to create an alert, which then appears whenever the bound
/// `isPresented` value is `true`. The `content` closure you provide to this
/// modifer produces a customized instance of the `Alert` type.
///
/// In the following example, a button presents a simple alert when
/// tapped, by updating a local `showAlert` property that binds to the alert.
///
///     @State private var showAlert = false
///     var body: some View {
///         Button("Tap to show alert") {
///             showAlert = true
///         }
///         .alert(isPresented: $showAlert) {
///             Alert(
///                 title: Text("Current Location Not Available"),
///                 message: Text("Your current location can’t be " +
///                                 "determined at this time.")
///             )
///         }
///     }
///
///
/// To customize the alert, add instances of the ``Alert/Button`` type, which
/// provides standardized buttons for common tasks like canceling and performing
/// destructive actions. The following example uses two buttons: a default
/// button labeled "Try Again" that calls a `saveWorkoutData` method,
/// and a "destructive" button that calls a `deleteWorkoutData` method.
///
///     @State private var showAlert = false
///     var body: some View {
///         Button("Tap to show alert") {
///             showAlert = true
///         }
///         .alert(isPresented: $showAlert) {
///             Alert(
///                 title: Text("Unable to Save Workout Data"),
///                 message: Text("The connection to the server was lost."),
///                 primaryButton: .default(
///                     Text("Try Again"),
///                     action: saveWorkoutData
///                 ),
///                 secondaryButton: .destructive(
///                     Text("Delete"),
///                     action: deleteWorkoutData
///                 )
///             )
///         }
///     }
///
///
/// The alert handles its own dismissal when the user taps one of the buttons in the alert, by setting
/// the bound `isPresented` value back to `false`.
///

@available(iOS 13.0, *)
public struct Alert {
    
    internal var title: Text
    
    internal var message: Text?
    
    internal var primaryButton: Button
    
    internal var secondaryButton: Button?
    
    internal var isSideBySide: Bool
    
    internal static func sideBySideButtons(title: Text, message: Text?, primaryButton: Button, secondaryButton: Button) -> Alert {
        Alert(title: title, message: message, primaryButton: primaryButton, secondaryButton: secondaryButton)
    }
    
    /// Creates an alert with one button.
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - message: The message to display in the body of the alert.
    ///   - dismissButton: The button that dismisses the alert.
    public init(title: Text, message: Text? = nil, dismissButton: Button? = nil) {
        if let dismissButtonValue = dismissButton {
            self.primaryButton = dismissButtonValue
        } else {
            self.primaryButton = .default(Text("OK"))
        }
        self.title = title
        self.message = message
        self.isSideBySide = false
    }
    
    /// Creates an alert with two buttons.
    ///
    /// The system determines the visual ordering of the buttons.
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - message: The message to display in the body of the alert.
    ///   - primaryButton: The first button to show in the alert.
    ///   - secondaryButton: The second button to show in the alert.
    public init(title: Text, message: Text? = nil, primaryButton: Button, secondaryButton: Button) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.isSideBySide = false
    }
    
    internal struct Presentation: AlertControllerConvertible {
        
        internal typealias Action = Button
        
        internal let alert: Alert
        
        internal let onDismiss: (() -> Void)?
        
        internal let viewID: ViewIdentity
        
        internal let itemID: AnyHashable?
        
        internal let sourceRect: CGRect
        
        internal var title: Text {
            alert.title
        }
        
        internal var message: Text? {
            alert.message
        }

        internal var buttons: [Button] {
            var alertButtons: [Button] = []
            
            alertButtons.append(alert.primaryButton)
            
            if let secondaryButton = alert.secondaryButton {
                alertButtons.append(secondaryButton)
            }
            
            return alertButtons
        }
        
        internal struct Key: HostPreferenceKey {

            internal typealias Value = Presentation?

            internal static func reduce(value: inout Alert.Presentation?, nextValue: () -> Alert.Presentation?) {
                
                guard value == nil else {
                    return
                }
                
                value = nextValue()
            }
        }
    }
    /// A button that represents an operation of an alert presentation.
    public struct Button: AlertActionConvertible {
        
        internal var style: Style
        
        internal var label: Text
        
        internal var action: (() -> Void)?
        
        internal enum Style: Equatable, Hashable {
            case `default`
            
            case cancel
            
            case destructive
        }
        
        /// Creates an alert button with the default style.
        public static func `default`(_ label: Text, action: (() -> Void)? = {}) -> Button {
            Button(style: .default, label: label, action: action)
        }
        
        /// Creates an alert button that indicates cancellation, with a custom label.
        public static func cancel(_ label: Text, action: (() -> Void)? = {}) -> Button {
            Button(style: .cancel, label: label, action: action)
        }
        
        /// Creates an alert button that indicates cancellation, with a system-provided label.
        public static func cancel(_ action: (() -> Void)? = {}) -> Button {
            Button(style: .cancel, label: Text("Cancel"), action: action)
        }
        
        /// Creates an alert button with a style that indicates a destructive action.
        public static func destructive(_ label: Text, action: (() -> Void)? = {}) -> Button {
            Button(style: .destructive, label: label, action: action)
        }
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Presents an alert to the user.
    ///
    /// Use this method when you need to show an alert that contains
    /// information from a binding to an optional data source that you provide.
    /// The example below shows a custom data source `FileInfo` whose
    /// properties configure the alert's `message` field:
    ///
    ///     struct FileInfo: Identifiable {
    ///         var id: String { name }
    ///         let name: String
    ///         let fileType: UTType
    ///     }
    ///
    ///     struct ConfirmImportAlert: View {
    ///         @State var alertDetails: FileInfo?
    ///         var body: some View {
    ///             Button("Show Alert") {
    ///                 alertDetails = FileInfo(name: "MyImageFile.png",
    ///                                         fileType: .png)
    ///             }
    ///             .alert(item: $alertDetails) { details in
    ///                 Alert(title: Text("Import Complete"),
    ///                       message: Text("""
    ///                         Imported \(details.name) \n File
    ///                         type: \(details.fileType.description).
    ///                         """),
    ///                       dismissButton: .default(Text("Dismiss")))
    ///             }
    ///         }
    ///     }
    ///
    ///
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the alert.
    ///     if `item` is non-`nil`, the system passes the contents to
    ///     the modifier's closure. You use this content to populate the fields
    ///     of an alert that you create that the system displays to the user.
    ///     If `item` changes, the system dismisses the currently displayed
    ///     alert and replaces it with a new one using the same process.
    ///   - content: A closure returning the alert to present.
    public func alert<Item>(item: Binding<Item?>, content: (Item) -> Alert) -> some View where Item : Identifiable {
        let itemValue = item.wrappedValue
        
        let alert = itemValue.map { identifiableValue -> Alert in
            content(identifiableValue)
        }
        
        let id = itemValue.map { identifiableValue -> AnyHashable in
            AnyHashable(identifiableValue.id)
        }
        
        return presentationCommon(alert, onDismiss: {
            item.wrappedValue = nil
        }, id: id)
    }
    
    /// Presents an alert to the user.
    ///
    /// Use this method when you need to show an alert to the user. The example
    /// below displays an alert that is shown when the user toggles a
    /// Boolean value that controls the presentation of the alert:
    ///
    ///     struct OrderCompleteAlert: View {
    ///         @State private var isPresented = false
    ///         var body: some View {
    ///             Button("Show Alert", action: {
    ///                 isPresented = true
    ///             })
    ///             .alert(isPresented: $isPresented) {
    ///                 Alert(title: Text("Order Complete"),
    ///                       message: Text("Thank you for shopping with us."),
    ///                       dismissButton: .default(Text("OK")))
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the alert that you create in the modifier's `content` closure. When the
    ///      user presses or taps OK the system sets `isPresented` to `false`
    ///     which dismisses the alert.
    ///   - content: A closure returning the alert to present.
    public func alert(isPresented: Binding<Bool>, content: () -> Alert) -> some View {
        guard isPresented.wrappedValue else {
            return presentationCommon(nil, onDismiss: {
                isPresented.wrappedValue = false
            }, id: nil)
        }
        
        let alert = content()
        
        return presentationCommon(alert, onDismiss: {
            isPresented.wrappedValue = false
        }, id: nil)
    }
    
    fileprivate func presentationCommon(_ alert: Alert?, onDismiss: (() -> Void)?, id: AnyHashable?) -> some View {
        modifier(AlertTransformModifier<Alert.Presentation.Key>(transform: { presentation, viewIdentity, rect in
            if let alertValue = alert {
                let newPresentation: Alert.Presentation = .init(alert: alertValue, onDismiss: onDismiss, viewID: viewIdentity, itemID: id, sourceRect: rect)
                presentation = newPresentation
            } else {
                presentation = nil
            }
        }))
    }
}
