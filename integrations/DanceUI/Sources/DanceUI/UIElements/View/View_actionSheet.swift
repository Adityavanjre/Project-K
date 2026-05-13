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

/// A representation of an action sheet presentation.
///
/// Use an action sheet when you want the user to make a choice between two
/// or more options, in response to their own action. If you want the user to
/// act in response to the state of the app or the system, rather than a user
/// action, use an ``Alert`` instead.
///
/// You show an action sheet by using the
/// ``View/actionSheet(isPresented:content:)`` view modifier to create an
/// action sheet, which then appears whenever the bound `isPresented` value is
/// `true`. The `content` closure you provide to this modifier produces a
/// customized instance of the `ActionSheet` type. To supply the options, create
/// instances of ``ActionSheet/Button`` to distinguish between ordinary options,
/// destructive options, and cancellation of the user's original action.
///
/// The action sheet handles its own dismissal by setting the bound
/// `isPresented` value back to `false` when the user taps a button in the
/// action sheet.
///
/// The following example creates an action sheet with three options: a Cancel
/// button, a destructive button, and a default button. The second and third of
/// these call methods are named `overwriteWorkout` and `appendWorkout`,
/// respectively.
///
///     @State private var showActionSheet = false
///     var body: some View {
///         Button("Tap to show action sheet") {
///             showActionSheet = true
///         }
///         .actionSheet(isPresented: $showActionSheet) {
///             ActionSheet(title: Text("Resume Workout Recording"),
///                         message: Text("Choose a destination for workout data"),
///                         buttons: [
///                             .cancel(),
///                             .destructive(
///                                 Text("Overwrite Current Workout"),
///                                 action: overwriteWorkout
///                             ),
///                             .default(
///                                 Text("Append to Current Workout"),
///                                 action: appendWorkout
///                             )
///                         ]
///             )
///         }
///     }
///
/// The system may interpret the order of items as they appear in the `buttons`
/// array to accommodate platform conventions. In this example, the Cancel
/// button is the first member of the array, but the action sheet puts it in its
/// standard position at the bottom of the sheet.
///

@available(iOS 13.0, *)
public struct ActionSheet {
    
    /// A button representing an operation of an action sheet presentation.
    public typealias Button = Alert.Button
    
    internal var title: Text
    
    internal var message: Text?
    
    internal var buttons: [Button]
    
    /// Creates an action sheet with the provided buttons.
    public init(title: Text,
                message: Text? = nil,
                buttons: [Button] = [.cancel()]) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }
    
    internal struct Presentation: AlertControllerConvertible {
        
        internal typealias Action = Button
        
        internal let title: Text
        
        internal let message: Text?
        
        internal let buttons: [Button]
        
        internal var onDismiss: (() -> Void)?
        
        internal let viewID: ViewIdentity
        
        internal let itemID: AnyHashable?
        
        internal let sourceRect: CGRect
        
        internal struct Key: HostPreferenceKey {
            
            internal typealias Value = Presentation?
            
            internal static func reduce(value: inout ActionSheet.Presentation?, nextValue: () -> ActionSheet.Presentation?) {
                if value == nil {
                    value = nextValue()
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Presents an action sheet using the given item as a data source for the
    /// sheet's content.
    ///
    /// Use this method when you need to populate the fields of an action sheet
    /// with content from a data source. The example below shows a custom data
    /// source, `FileDetails`, that provides data to populate the action sheet:
    ///
    ///     struct FileDetails: Identifiable {
    ///         var id: String { name }
    ///         let name: String
    ///         let fileType: UTType
    ///     }
    ///     struct ConfirmFileImport: View {
    ///         @State var sheetDetail: FileDetails?
    ///         var body: some View {
    ///             Button("Show Action Sheet") {
    ///                 sheetDetail = FileDetails(name: "MyImageFile.png",
    ///                                           fileType: .png)
    ///             }
    ///             .actionSheet(item: $sheetDetail) { detail in
    ///                 ActionSheet(
    ///                     title: Text("File Import"),
    ///                     message: Text("""
    ///                              Import \(detail.name)?
    ///                              File Type: \(detail.fileType.description)
    ///                              """),
    ///                     buttons: [
    ///                         .destructive(Text("Import"),
    ///                                      action: importFile),
    ///                         .cancel()
    ///                     ])
    ///             }
    ///         }
    ///
    ///         func importFile() {
    ///             // Handle import action.
    ///         }
    ///     }
    ///
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the action
    ///     sheet. When `item` is non-`nil`, the system passes
    ///     the contents to the modifier's closure. You use this content
    ///     to populate the fields of an action sheet that you create that the
    ///     system displays to the user. If `item` changes, the system
    ///     dismisses the currently displayed action sheet and replaces it
    ///     with a new one using the same process.
    ///   - content: A closure returning the ``ActionSheet`` you create.
    public func actionSheet<T>(item: Binding<T?>, content: (T) -> ActionSheet) -> some View where T : Identifiable {
        
        let itemValue = item.wrappedValue
        
        let actionSheet = itemValue.map { identifiableValue -> ActionSheet in
            content(identifiableValue)
        }
        
        let id = itemValue.map { identifiableValue -> AnyHashable in
            AnyHashable(identifiableValue.id)
        }
        
        return presentationCommon(actionSheet, onDismiss: {
            item.wrappedValue = nil
        }, id: id)
    }
    
    /// Presents an action sheet when a given condition is true.
    ///
    /// In the example below, a button conditionally presents an action sheet
    /// depending upon the value of a bound Boolean variable. When the Boolean
    /// value is set to `true`, the system displays an action sheet with both
    /// destructive and default actions:
    ///
    ///     struct ConfirmEraseItems: View {
    ///         @State private var isShowingSheet = false
    ///         var body: some View {
    ///             Button("Show Action Sheet", action: {
    ///                 isShowingSheet = true
    ///             })
    ///             .actionSheet(isPresented: $isShowingSheet) {
    ///                 ActionSheet(
    ///                     title: Text("Permanently erase the items in the Trash?"),
    ///                     message: Text("You can't undo this action."),
    ///                     buttons:[
    ///                         .destructive(Text("Empty Trash"),
    ///                                      action: emptyTrashAction),
    ///                         .cancel()
    ///                     ]
    ///                 )}
    ///         }
    ///
    ///         func emptyTrashAction() {
    ///             // Handle empty trash action.
    ///         }
    ///     }
    ///
    ///
    /// > Note: In regular size classes in iOS, the system renders alert sheets
    ///    as a popover that the user dismisses by tapping anywhere outside the
    ///    popover, rather than displaying the default dismiss button.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the action sheet that you create in the modifier's
    ///     `content` closure. When the user presses or taps the sheet's default
    ///     action button the system sets this value to `false` dismissing
    ///     the sheet.
    ///   - content: A closure returning the `ActionSheet` to present.
    public func actionSheet(isPresented: Binding<Bool>, content: () -> ActionSheet) -> some View {
        
        guard isPresented.wrappedValue else {
            return presentationCommon(nil, onDismiss: {
                isPresented.wrappedValue = false
            }, id: nil)
        }
        
        let actionSheet = content()
        
        return presentationCommon(actionSheet, onDismiss: {
            isPresented.wrappedValue = false
        }, id: nil)
    }
    
    fileprivate func presentationCommon(_ actionSheet: ActionSheet?, onDismiss: (() -> Void)?, id: AnyHashable?) -> some View {
        modifier(AlertTransformModifier<ActionSheet.Presentation.Key>(transform: { presentation, viewIdentity, rect in
            if let actionSheetValue = actionSheet {
                let newPresentation: ActionSheet.Presentation = .init(title: actionSheetValue.title, message: actionSheetValue.message, buttons: actionSheetValue.buttons, onDismiss: onDismiss, viewID: viewIdentity, itemID: id, sourceRect: rect)
                presentation = newPresentation
            } else {
                presentation = nil
            }
        }))
    }
}
