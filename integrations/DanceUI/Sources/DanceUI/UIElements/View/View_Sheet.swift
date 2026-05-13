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
extension View {
    
    /// Presents a sheet using the given item as a data source
    /// for the sheet's content.
    ///
    /// Use this method when you need to present a modal view with content
    /// from a custom data source. The example below shows a custom data source
    /// `InventoryItem` that the `content` closure uses to populate the display
    /// the action sheet shows to the user:
    ///
    ///     struct ShowPartDetail: View {
    ///         @State var sheetDetail: InventoryItem?
    ///         var body: some View {
    ///             Button("Show Part Details") {
    ///                 sheetDetail = InventoryItem(
    ///                     id: "0123456789",
    ///                     partNumber: "Z-1234A",
    ///                     quantity: 100,
    ///                     name: "Widget")
    ///             }
    ///             .sheet(item: $sheetDetail,
    ///                    onDismiss: didDismiss) { detail in
    ///                 VStack(alignment: .leading, spacing: 20) {
    ///                     Text("Part Number: \(detail.partNumber)")
    ///                     Text("Name: \(detail.name)")
    ///                     Text("Quantity On-Hand: \(detail.quantity)")
    ///                 }
    ///                 .onTapGesture {
    ///                     sheetDetail = nil
    ///                 }
    ///             }
    ///         }
    ///
    ///         func didDismiss() {
    ///             // Handle the dismissing action.
    ///         }
    ///     }
    ///
    ///     struct InventoryItem: Identifiable {
    ///         var id: String
    ///         let partNumber: String
    ///         let quantity: Int
    ///         let name: String
    ///     }
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the sheet.
    ///     When `item` is non-`nil`, the system passes the item's content to
    ///     the modifier's closure. You display this content in a sheet that you
    ///     create that the system displays to the user. If `item` changes,
    ///     the system dismisses the sheet and replaces it with a new one
    ///     using the same process.
    ///   - onDismiss: The closure to execute when dismissing the sheet.
    ///   - content: A closure returning the content of the sheet.
    public func sheet<Item, Content>(item: Binding<Item?>,
                                     onDismiss: (() -> Void)? = nil,
                                     @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View {
        modifier(ItemSheetPresentationModifier<Content,Item>(item: item,
                                                             onDismiss: onDismiss,
                                                             sheetContent: content,
                                                             overFullscreen: false,
                                                             drawsBackground: true))
    }
    
    /// Presents a sheet when a binding to a Boolean value that you
    /// provide is true.
    ///
    /// Use this method when you want to present a modal view to the
    /// user when a Boolean value you provide is true. The example
    /// below displays a modal view of the mockup for a software license
    /// agreement when the user toggles the `isShowingSheet` variable by
    /// clicking or tapping on the "Show License Agreement" button:
    ///
    ///     struct ShowLicenseAgreement: View {
    ///         @State private var isShowingSheet = false
    ///         var body: some View {
    ///             Button(action: {
    ///                 isShowingSheet.toggle()
    ///             }) {
    ///                 Text("Show License Agreement")
    ///             }
    ///             .sheet(isPresented: $isShowingSheet,
    ///                    onDismiss: didDismiss) {
    ///                 VStack {
    ///                     Text("License Agreement")
    ///                         .font(.title)
    ///                         .padding(50)
    ///                     Text("""
    ///                             Terms and conditions go here.
    ///                         """)
    ///                         .padding(50)
    ///                     Button("Dismiss",
    ///                            action: { isShowingSheet.toggle() })
    ///                 }
    ///             }
    ///         }
    ///
    ///         func didDismiss() {
    ///             // Handle the dismissing action.
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the sheet that you create in the modifier's
    ///     `content` closure.
    ///   - onDismiss: The closure to execute when dismissing the sheet.
    ///   - content: A closure that returns the content of the sheet.
    public func sheet<Content>(isPresented: Binding<Bool>,
                               onDismiss: (() -> Void)? = nil,
                               @ViewBuilder content: @escaping () -> Content) -> some View where Content : View {
        modifier(SheetPresentationModifier(isPresented: isPresented,
                                           onDismiss: onDismiss,
                                           sheetContent: content,
                                           overFullscreen: false,
                                           drawsBackground: true))
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Presents a modal view that covers as much of the screen as
    /// possible using the binding you provide as a data source for the
    /// sheet's content.
    ///
    /// Use this method to display a modal view that covers as much of the
    /// screen as possible. In the example below a custom structure —
    /// `CoverData` — provides data for the full-screen view to display in the
    /// `content` closure when the user clicks or taps the
    /// "Present Full-Screen Cover With Data" button:
    ///
    ///     struct FullScreenCoverItemOnDismissContent: View {
    ///         @State var coverData: CoverData?
    ///         var body: some View {
    ///             Button("Present Full-Screen Cover With Data") {
    ///                 coverData = CoverData(body: "Custom Data")
    ///             }
    ///             .fullScreenCover(item: $coverData,
    ///                              onDismiss: didDismiss) { details in
    ///                 VStack(spacing: 20) {
    ///                     Text("\(details.body)")
    ///                 }
    ///                 .onTapGesture {
    ///                     coverData = nil
    ///                 }
    ///             }
    ///         }
    ///
    ///         func didDismiss() {
    ///             // Handle the dismissing action.
    ///         }
    ///
    ///     }
    ///
    ///     struct CoverData: Identifiable {
    ///         var id: String {
    ///             return body
    ///         }
    ///         let body: String
    ///     }
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the sheet.
    ///     When `item` is non-`nil`, the system passes the contents to
    ///     the modifier's closure. You display this content in a sheet that you
    ///     create that the system displays to the user. If `item` changes,
    ///     the system dismisses the currently displayed sheet and replaces
    ///     it with a new one using the same process.
    ///   - onDismiss: The closure to execute when dismissing the modal view.
    ///   - content: A closure returning the content of the modal view.
    public func fullScreenCover<Item, Content>(item: Binding<Item?>,
                                               onDismiss: (() -> Void)? = nil,
                                               @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item: Identifiable, Content: View {
        modifier(ItemSheetPresentationModifier<Content,Item>(item: item,
                                                             onDismiss: onDismiss,
                                                             sheetContent: content,
                                                             overFullscreen: true,
                                                             drawsBackground: true))
    }
    
    /// Presents a modal view that covers as much of the screen as
    /// possible when binding to a Boolean value you provide is true.
    ///
    /// Use this method to show a modal view that covers as much of the screen
    /// as possible. The example below displays a custom view when the user
    /// toggles the value of the `isPresenting` binding:
    ///
    ///     struct FullScreenCoverPresentedOnDismiss: View {
    ///         @State private var isPresenting = false
    ///         var body: some View {
    ///             Button("Present Full-Screen Cover") {
    ///                 isPresenting.toggle()
    ///             }
    ///             .fullScreenCover(isPresented: $isPresenting,
    ///                              onDismiss: didDismiss) {
    ///                 VStack {
    ///                     Text("A full-screen modal view.")
    ///                         .font(.title)
    ///                     Text("Tap to Dismiss")
    ///                 }
    ///                 .onTapGesture {
    ///                     isPresenting.toggle()
    ///                 }
    ///                 .foregroundColor(.white)
    ///                 .frame(maxWidth: .infinity,
    ///                        maxHeight: .infinity)
    ///                 .background(Color.blue)
    ///                 .ignoresSafeArea(edges: .all)
    ///             }
    ///         }
    ///
    ///         func didDismiss() {
    ///             // Handle the dismissing action.
    ///         }
    ///     }
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the sheet.
    ///   - onDismiss: The closure to execute when dismissing the modal view.
    ///   - content: A closure that returns the content of the modal view.
    public func fullScreenCover<Content>(isPresented: Binding<Bool>,
                                         onDismiss: (() -> Void)? = nil,
                                         @ViewBuilder content: @escaping () -> Content) -> some View where Content: View {
        modifier(SheetPresentationModifier(isPresented: isPresented,
                                           onDismiss: onDismiss,
                                           sheetContent: content,
                                           overFullscreen: true,
                                           drawsBackground: true))
    }
}

@available(iOS 13.0, *)
fileprivate struct SheetPresentationModifier<ContentView: View>: ViewModifier {
    
    @Namespace
    fileprivate var namespace
    
    @Binding
    fileprivate var isPresented: Bool
    
    fileprivate var onDismiss: (() -> ())?
    
    fileprivate var sheetContent: () -> ContentView
    
    fileprivate var overFullscreen: Bool
    
    fileprivate var drawsBackground: Bool
    
    fileprivate func body(content: Content) -> some View {
        
        EnvironmentValues.reader { environments in
            content.transactionalPreferenceTransform(key: SheetPreference.Key.self) { preferenceValue, transaction in
                if isPresented {
                    switch preferenceValue {
                    case .empty(let transaction):
                        
                        let presentationMode = self.$isPresented.projecting(PresentationMode.FromIsPresented())
                        
                        let sheet = SheetContent {
                            sheetContent()
                                .styleContext(SheetStyleContext())
                        }
                        .environment(\.presentationMode, presentationMode)
                        
                        let anySheetView = AnyView(sheet)
                        
                        let sheetPreference = SheetPreference(content: anySheetView,
                                                              onDismiss: { isPresentedSheet in
                            if isPresentedSheet {
                                isPresented = false
                            }
                            
                            if let onDissmissCallback = onDismiss {
                                onDissmissCallback()
                            }
                        },
                                                              viewID: namespace,
                                                              itemID: nil,
                                                              overFullscreen: overFullscreen,
                                                              drawsBackground: drawsBackground,
                                                              transaction: transaction,
                                                              environment: environments)
                        
                        preferenceValue = .sheet(sheetPreference)
                    case .sheet:
                        print("Currently, only presenting a single sheet is supported.\\nThe next sheet will be presented when the currently presented sheet gets dismissed.")
                    }
                } else {
                    if case .empty = preferenceValue {
                        preferenceValue = .empty(transaction)
                    }
                }
            }
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct SheetContent<Content: View>: View {
    
    fileprivate var content: Content
    
    fileprivate init(contentBlock: () -> Content) {
        self.content = contentBlock()
    }
    
    fileprivate var body: some View {
        content
            .environment(\.tintAdjustmentMode, nil)
    }
}

@available(iOS 13.0, *)
fileprivate struct ItemSheetPresentationModifier<ContentView: View, Item: Identifiable>: ViewModifier {
    
    @Namespace
    fileprivate var namespace
    
    @Binding
    fileprivate var item: Item?
    
    fileprivate var onDismiss: (() -> ())?
    
    fileprivate var sheetContent: (Item) -> ContentView
    
    fileprivate var overFullscreen: Bool
    
    fileprivate var drawsBackground: Bool
    
    fileprivate func body(content: Content) -> some View {
        EnvironmentValues.reader { environments in
            content.transactionalPreferenceTransform(key: SheetPreference.Key.self) { preferenceValue, transaction in
                if let itemID = item {
                    switch preferenceValue {
                    case .empty(let transaction):
                        
                        let presentationMode = self.$item.projecting(PresentationMode.FromItem<Item>())
                        
                        let sheet = SheetContent {
                            sheetContent(itemID)
                                .styleContext(SheetStyleContext())
                        }
                        .environment(\.presentationMode, presentationMode)
                        
                        let anySheetView = AnyView(sheet)
                        
                        let sheetPreference = SheetPreference(content: anySheetView,
                                                              onDismiss: { isPresentedSheet in
                            if isPresentedSheet {
                                item = nil
                            }
                            
                            if let onDissmissCallback = onDismiss {
                                onDissmissCallback()
                            }
                        },
                                                              viewID: namespace,
                                                              itemID: AnyHashable(itemID.id),
                                                              overFullscreen: overFullscreen,
                                                              drawsBackground: drawsBackground,
                                                              transaction: transaction,
                                                              environment: environments)
                        
                        preferenceValue = .sheet(sheetPreference)
                    case .sheet:
                        print("Currently, only presenting a single sheet is supported.\\nThe next sheet will be presented when the currently presented sheet gets dismissed.")
                    }
                } else {
                    if case .empty = preferenceValue {
                        preferenceValue = .empty(transaction)
                    }
                }
            }
        }
    }
}
