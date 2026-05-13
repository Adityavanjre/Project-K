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

/// An attachment anchor for a popover.
@available(iOS 13.0, *)
public enum PopoverAttachmentAnchor {

    /// The anchor point for the popover relative to the source's frame.
    case rect(Anchor<CGRect>.Source)

    /// The anchor point for the popover expressed as a unit point  that
    /// describes possible alignments relative to a DanceUI view.
    case point(UnitPoint)
    
    /// The margin between the popover and the specified position
    case margin(CGFloat)
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension View {

    /// Presents a popover using the given item as a data source for the
    /// popover's content.
    ///
    /// Use this method when you need to present a popover with content
    /// from a custom data source. The two examples below use data in
    /// the `PopoverModel` structures to populate the views in the `content`
    /// closures that the popovers display to the user:
    ///
    ///     struct PopoverDemo: View {
    ///         @State var popover: PopoverModel?
    ///
    ///         var body: some View {
    ///             VStack(spacing: 150) {
    ///                 Button("First Popover", action: {
    ///                     popover = PopoverModel(body: "Custom message #1.")
    ///                 })
    ///                 .popover(item: $popover) { detail in
    ///                     Text("\(detail.body)")
    ///                 }
    ///
    ///                 Button("Second Popover", action: {
    ///                     popover = PopoverModel(body: "Custom message #2.")
    ///                 })
    ///                 .popover(item: $popover) { detail in
    ///                     Text("\(detail.body)")
    ///                 }
    ///             }
    ///         }
    ///
    ///         struct PopoverModel: Identifiable {
    ///             var id: String { body }
    ///             let body: String
    ///         }
    ///     }
    ///
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover.
    ///     When `item` is non-`nil`, the system passes the contents to
    ///     the modifier's closure. You use this content to populate the fields
    ///     of a popover that you create that the system displays to the user.
    ///     If `item` changes, the system dismisses the currently presented
    ///     popover and replaces it with a new popover using the same process.
    ///   - attachmentAnchor: The positioning anchor that defines the
    ///     attachment point of the popover in macOS. The default is
    ///     ``Anchor/Source/bounds``. iOS ignores this parameter.
    ///   - arrowEdges: The edge of the `attachmentAnchor` that defines the
    ///     location of the popover's arrow. The default is ``PopoverPresentation/ArrowEdge/top``.
    ///   - content: A closure returning the content of the popover.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func popover<Item, Content>(item: Binding<Item?>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdges: PopoverPresentation.ArrowEdge = .top, minimumPopoverSize: CGSize = .zero, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View {
        self.modifier(ItemPopoverPresentationModifier(item: item,
                                                      onDismiss: nil,
                                                      popoverContent: content,
                                                      attachmentAnchor: attachmentAnchor,
                                                      arrowEdge: arrowEdges,
                                                      minimumPopoverSize: minimumPopoverSize))
    }

    @available(iOS, deprecated: 100000.0, renamed: "View.popover(item:attachmentAnchor:arrowEdges:minimumPopoverSize:content:)")
    @_disfavoredOverload
    public func popover<Item, Content>(item: Binding<Item?>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge = .top, minimumPopoverSize: CGSize = .zero, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View {
        self.modifier(ItemPopoverPresentationModifier(item: item,
                                                      onDismiss: nil,
                                                      popoverContent: content,
                                                      attachmentAnchor: attachmentAnchor,
                                                      arrowEdge: .init(arrowEdge),
                                                      minimumPopoverSize: minimumPopoverSize))
    }


    /// Presents a popover when a given condition is true.
    ///
    /// Use this method to show a popover whose contents are a DanceUI view
    /// that you provide when a bound Boolean variable is `true`. In the
    /// example below, a popover displays whenever the user toggles
    /// the `isShowingPopover` state variable by pressing the
    /// "Show Popover" button:
    ///
    ///     struct PopoverView: View {
    ///         @State private var isShowingPopover = false
    ///         var body: some View {
    ///             Button("Show Popover", action: {
    ///                 self.isShowingPopover = true
    ///             })
    ///             .popover(isPresented: $isShowingPopover) {
    ///                 PopoverView()
    ///             }
    ///         }
    ///     }
    ///
    ///     struct PopoverView: View {
    ///         var body: some View {
    ///             Text("Popover Content")
    ///                 .padding()
    ///         }
    ///     }
    ///
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the popover content that you return from the modifier's
    ///     `content` closure.
    ///   - attachmentAnchor: The positioning anchor that defines the
    ///     attachment point of the popover in macOS. The default is
    ///     ``Anchor/Source/bounds``. iOS ignores this parameter.
    ///   - arrowEdges: The edge of the `attachmentAnchor` that defines the
    ///     location of the popover's arrow. The default is ``PopoverPresentation/ArrowEdge/top``.
    ///   - content: A closure returning the content of the popover.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func popover<Content>(isPresented: Binding<Bool>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdges: PopoverPresentation.ArrowEdge = .top, minimumPopoverSize: CGSize = .zero, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View {
        self.popover(isPresented: isPresented,
                     isDetachable: false,
                     attachmentAnchor: attachmentAnchor,
                     arrowEdge: arrowEdges,
                     minimumPopoverSize: minimumPopoverSize,
                     content: content)
    }
    
    @available(iOS, deprecated: 100000.0, renamed: "View.popover(isPresented:attachmentAnchor:arrowEdges:minimumPopoverSize:content:)")
    @_disfavoredOverload
    public func popover<Content>(isPresented: Binding<Bool>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge = .top, minimumPopoverSize: CGSize = .zero, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View {
        self.popover(isPresented: isPresented,
                     isDetachable: false,
                     attachmentAnchor: attachmentAnchor,
                     arrowEdge: .init(arrowEdge),
                     minimumPopoverSize: minimumPopoverSize,
                     content: content)
    }
    
    @inline(__always)
    internal func popover<Content>(isPresented: Binding<Bool>, isDetachable: Bool, attachmentAnchor: PopoverAttachmentAnchor, arrowEdge: PopoverPresentation.ArrowEdge, minimumPopoverSize: CGSize = .zero, content: @escaping () -> Content)  -> some View where Content : View {
        self.modifier(PopoverPresentationModifier(isPresented: isPresented,
                                                  popoverContent: content,
                                                  attachmentAnchor: attachmentAnchor,
                                                  arrowEdge: arrowEdge,
                                                  isDetachable: isDetachable,
                                                  minimumPopoverSize: minimumPopoverSize))
    }
}

@available(iOS 13.0, *)
fileprivate struct ItemPopoverPresentationModifier<Item, Content> : EnvironmentalModifier where Item : Identifiable, Content : View {
    
    fileprivate typealias ResolvedModifier = PopoverModifier

    @Binding
    fileprivate var item: Item?

    fileprivate var onDismiss: (() -> ())?

    fileprivate var popoverContent: (Item) -> Content

    fileprivate var attachmentAnchor: PopoverAttachmentAnchor

    fileprivate var arrowEdge: PopoverPresentation.ArrowEdge
    
    fileprivate var minimumPopoverSize: CGSize

    fileprivate func resolve(in environment: EnvironmentValues) -> PopoverModifier {
        PopoverModifier(_viewID: IdentityLink(),
                        item: $item,
                        onDismiss: onDismiss,
                        popoverContent: popoverContent,
                        attachmentAnchor: attachmentAnchor,
                        arrowEdge: arrowEdge,
                        environment: environment,
                        minimumPopoverSize: minimumPopoverSize)
    }
    
    fileprivate struct PopoverModifier : ViewModifier {

        fileprivate var _viewID: IdentityLink

        @Binding
        fileprivate var item: Item?

        fileprivate var onDismiss: (() -> ())?

        fileprivate var popoverContent: (Item) -> Content

        fileprivate var attachmentAnchor: PopoverAttachmentAnchor

        fileprivate var arrowEdge: PopoverPresentation.ArrowEdge

        fileprivate var environment: EnvironmentValues
        
        fileprivate var minimumPopoverSize: CGSize
        
        fileprivate var anchor : Anchor<CGRect>.Source? {
            return item.map { _ in
                switch attachmentAnchor {
                case .rect(let anchor):
                    return anchor
                case .point(let unitPoint):
                    let unitRect = UnitRect(x: unitPoint.x, y: unitPoint.y, width: 0, height: 0)
                    let value = AnchorBox<UnitRect>(value: unitRect)
                    return .init(box: value)
                case .margin(let margin):
                    let value = AnchorBox(value: PopoverMargin(margin: margin, edge: arrowEdge))
                    return .init(box: value)
                }
            }
        }
        
        fileprivate var viewID : ViewIdentity {
            let id = _viewID._value
            if id != .zero {
                return id
            }
            _danceuiFatalError("popover viewID is zero")
        }

        fileprivate func dismiss() {
            LogService.debug(module: .popover,
                             keyword: .bindingUpdate, "Popover dismiss reset item Binding")
            item = nil
        }
        
        fileprivate func wrappedContent(item: Item) -> AnyView {
            let content = popoverContent(item)
            let mode = self.$item.projecting(PresentationMode.FromItem())
            return AnyView(PopoverContent(minimumPopoverSize: minimumPopoverSize, content: content, mode: mode))
        }
        
        fileprivate func body(content: _ViewModifier_Content<PopoverModifier>) -> some View {
            content.transformAnchorPreference(key: PopoverPresentation.Key.self, value: .init(box: OptionalAnchorBox(value: anchor))) { value, anchor in
                guard let item = item else {
                    return
                }
                let content = wrappedContent(item: item)
                value.append(PopoverPresentation(content: content,
                                                 arrowEdge: arrowEdge,
                                                 targetAnchor: anchor,
                                                 onDismiss: { dismiss() },
                                                 isDetachable: false,
                                                 viewID: viewID,
                                                 itemID: AnyHashable(item.id),
                                                 environment: environment))
            }
        }
    }

}

@available(iOS 13.0, *)
fileprivate struct PopoverPresentationModifier<Content : View> : EnvironmentalModifier {
    
    fileprivate typealias ResolvedModifier = PopoverModifier
    
    @Binding
    fileprivate var isPresented: Bool

    fileprivate var popoverContent: () -> Content

    fileprivate var attachmentAnchor: PopoverAttachmentAnchor

    fileprivate var arrowEdge: PopoverPresentation.ArrowEdge

    fileprivate var isDetachable: Bool
    
    fileprivate var minimumPopoverSize: CGSize

    fileprivate func resolve(in environment: EnvironmentValues) -> PopoverModifier {
        PopoverModifier(_viewID: IdentityLink(),
                        isPresented: $isPresented,
                        popoverContent: popoverContent,
                        attachmentAnchor: attachmentAnchor,
                        arrowEdge: arrowEdge,
                        isDetachable: isDetachable,
                        environment: environment,
                        minimumPopoverSize: minimumPopoverSize)
    }
    
    fileprivate struct PopoverModifier : ViewModifier {
        
        // 0x0
        fileprivate var _viewID: IdentityLink

        @Binding
        fileprivate var isPresented: Bool

        fileprivate var popoverContent: () -> Content

        fileprivate var attachmentAnchor: PopoverAttachmentAnchor

        fileprivate var arrowEdge: PopoverPresentation.ArrowEdge

        fileprivate var isDetachable: Bool

        fileprivate var environment: EnvironmentValues
        
        fileprivate var minimumPopoverSize: CGSize
        
        fileprivate var anchor : Anchor<CGRect>.Source? {
            guard isPresented else {
                return nil
            }
            switch attachmentAnchor {
            case .rect(let anchor):
                return anchor
            case .point(let unitPoint):
                let unitRect = UnitRect(x: unitPoint.x, y: unitPoint.y, width: 0, height: 0)
                let value = AnchorBox<UnitRect>(value: unitRect)
                return .init(box: value)
            case .margin(let margin):
                let value = AnchorBox(value: PopoverMargin(margin: margin, edge: arrowEdge))
                return .init(box: value)
            }
        }
        
        fileprivate func dismiss() {
            LogService.debug(module: .popover,
                             keyword: .bindingUpdate, "Popover dismiss reset isPresented Binding")
            isPresented = false
        }
        
        fileprivate var viewID : ViewIdentity {
            let id = _viewID._value
            if id != .zero {
                return id
            }
            _danceuiFatalError("popover viewID is zero")
        }
        
        fileprivate var wrappedContent : AnyView {
            let content = popoverContent()
            let mode = self.$isPresented.projecting(PresentationMode.FromIsPresented())
            return AnyView(PopoverContent(minimumPopoverSize: minimumPopoverSize, content: content, mode: mode))
        }
        
        fileprivate func body(content:  _ViewModifier_Content<PopoverModifier>) -> some View {
            content.transformAnchorPreference(key: PopoverPresentation.Key.self, value: .init(box: OptionalAnchorBox(value: anchor))) { value, anchor in
                guard isPresented else {
                    return
                }
                value.append(PopoverPresentation(content: wrappedContent,
                                                 arrowEdge: arrowEdge,
                                                 targetAnchor: anchor,
                                                 onDismiss: { dismiss() },
                                                 isDetachable: isDetachable,
                                                 viewID: viewID,
                                                 itemID: nil,
                                                 environment: environment))
            }
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct PopoverContent<Content : View> : View {
    

    fileprivate let minimumPopoverSize: CGSize

    fileprivate var content: Content

    @Binding
    fileprivate var mode: PresentationMode
    
    fileprivate init(minimumPopoverSize: CGSize, content: Content, mode: Binding<PresentationMode>) {
        self.minimumPopoverSize = minimumPopoverSize == .zero ? CGSize(width: 68, height: 68) : minimumPopoverSize
        self.content = content
        self._mode = mode
    }
    
    fileprivate var body: some View {
        content
            .frame(minWidth: minimumPopoverSize.width, minHeight: minimumPopoverSize.height)
            .environment(\.presentationMode, $mode)
            .environment(\.tintAdjustmentMode, nil)
    }

}

@available(iOS 13.0, *)
fileprivate struct PopoverMargin {
    
    fileprivate let margin: CGFloat
    
    fileprivate var edge: Edge = .top
    
    fileprivate init(margin: CGFloat, edge: PopoverPresentation.ArrowEdge) {
        self.margin = margin
        let edges = edge.edges
        self.edge = edges.first ?? .top
    }
}

@available(iOS 13.0, *)
extension PopoverMargin: AnchorProtocol {
    
    fileprivate typealias AnchorValue = CGRect
    
    fileprivate static let defaultAnchor: CGRect = .zero
    
    fileprivate func prepare(size: CGSize, transform: ViewTransform) -> CGRect {
        var point: CGPoint = .zero
        switch edge {
        case .top:
            point = .init(x: 0.5, y: 0)
        case .bottom:
            point = .init(x: 0.5, y: 1)
        case .leading:
            point = .init(x: 0, y: 0.5)
        case .trailing:
            point = .init(x: 1, y: 0.5)
        }
        
        let newRect = CGRect(x: point.x * size.width,
                             y: point.y * size.height,
                             width: 0,
                             height: 0)
        
        guard newRect.isValid else {
            return updateMargin(newRect)
        }
        
        var cornerPoints = newRect.cornerPoints
        cornerPoints.convert(to: .global, transform: transform)
        assert(cornerPoints.count == 4, "incorrect count")
        return updateMargin(.init(cornerPoints: cornerPoints[..<4]))
    }
    
    fileprivate func updateMargin(_ rect: CGRect) -> CGRect {
        var result = rect
        switch edge {
        case .top:
            result.origin.y -= margin
        case .bottom:
            result.origin.y += margin
        case .leading:
            result.origin.x -= margin
        case .trailing:
            result.origin.x += margin
        }
        return result
    }
    
    fileprivate static func valueIsEqual(lhs: CGRect, rhs: CGRect) -> Bool {
        lhs.equalTo(rhs)
    }
}
