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

import UIKit

/// A wrapper for a UIKit view that you use to integrate that view into your
/// DanceUI view hierarchy.
///
/// Use a ``UIViewRepresentable`` instance to create and manage a
/// <https://developer.apple.com/documentation/UIKit/UIView> object in your DanceUI
/// interface. Adopt this protocol in one of your app's custom instances, and
/// use its methods to create, update, and tear down your view. The creation and
/// update processes parallel the behavior of DanceUI views, and you use them to
/// configure your view with your app's current state information. Use the
/// teardown process to remove your view cleanly from your DanceUI. For example,
/// you might use the teardown process to notify other objects that the view is
/// disappearing.
///
/// To add your view into your DanceUI interface, create your
/// ``UIViewRepresentable`` instance and add it to your DanceUI interface. The
/// system calls the methods of your representable instance at appropriate times
/// to create and update the view. The following example shows the inclusion of
/// a custom `MyRepresentedCustomView` structure in the view hierarchy.
///
///     struct ContentView: View {
///        var body: some View {
///           VStack {
///              Text("Global Sales")
///              MyRepresentedCustomView()
///           }
///        }
///     }
///
/// The system doesn't automatically communicate changes occurring within your
/// view to other parts of your DanceUI interface. When you want your view to
/// coordinate with other DanceUI views, you must provide a
/// ``NSViewControllerRepresentable/Coordinator`` instance to facilitate those
/// interactions. For example, you use a coordinator to forward target-action
/// and delegate messages from your view to any DanceUI views.
@available(iOS 13.0, *)
public protocol UIViewRepresentable : View where Self.Body == Never {

    /// The type of view to present.
    associatedtype UIViewType : UIView

    /// A type to coordinate with the view.
    associatedtype Coordinator = Void

    typealias Context = UIViewRepresentableContext<Self>

    /// Creates the view object and configures its initial state.
    ///
    /// You must implement this method and use it to create your view object.
    /// Configure the view using your app's current data and contents of the
    /// `context` parameter. The system calls this method only once, when it
    /// creates your view for the first time. For all subsequent updates, the
    /// system calls the ``UIViewRepresentable/updateUIView(_:context:)``
    /// method.
    ///
    /// - Parameter context: A context structure containing information about
    ///   the current state of the system.
    ///
    /// - Returns: Your UIKit view configured with the provided information.
    @MainActor @preconcurrency func makeUIView(context: Self.Context) -> Self.UIViewType

    /// Updates the state of the specified view with new information from
    /// DanceUI.
    ///
    /// When the state of your app changes, DanceUI updates the portions of your
    /// interface affected by those changes. DanceUI calls this method for any
    /// changes affecting the corresponding UIKit view. Use this method to
    /// update the configuration of your view to match the new state information
    /// provided in the `context` parameter.
    ///
    /// - Parameters:
    ///   - uiView: Your custom view object.
    ///   - context: A context structure containing information about the current
    ///     state of the system.
    @MainActor @preconcurrency func updateUIView(_ uiView: Self.UIViewType, context: Self.Context)

    /// Cleans up the presented UIKit view (and coordinator) in anticipation of
    /// their removal.
    ///
    /// Use this method to perform additional clean-up work related to your
    /// custom view. For example, you might use this method to remove observers
    /// or update other parts of your DanceUI interface.
    ///
    /// - Parameters:
    ///   - uiView: Your custom view object.
    ///   - coordinator: The custom coordinator instance you use to communicate
    ///     changes back to DanceUI. If you do not use a custom coordinator, the
    ///     system provides a default instance.
    @MainActor @preconcurrency static func dismantleUIView(_ uiView: Self.UIViewType, coordinator: Self.Coordinator)

    /// Creates the custom instance that you use to communicate changes from
    /// your view to other parts of your DanceUI interface.
    ///
    /// Implement this method if changes to your view might affect other parts
    /// of your app. In your implementation, create a custom Swift instance that
    /// can communicate with other parts of your interface. For example, you
    /// might provide an instance that binds its variables to DanceUI
    /// properties, causing the two to remain synchronized. If your view doesn't
    /// interact with other parts of your app, providing a coordinator is
    /// unnecessary.
    ///
    /// DanceUI calls this method before calling the
    /// ``UIViewRepresentable/makeUIView(context:)`` method. The system provides
    /// your coordinator either directly or as part of a context structure when
    /// calling the other methods of your representable instance.
    @MainActor @preconcurrency func makeCoordinator() -> Self.Coordinator

    @MainActor @preconcurrency func _identifiedViewTree(in uiView: UIViewType) -> _IdentifiedViewTree

    @MainActor @preconcurrency func _overrideSizeThatFits(_ size: inout CGSize, in proposedSize: _ProposedSize, uiView: UIViewType)

    @MainActor @preconcurrency func _overrideLayoutTraits(_ layoutTraits: inout _LayoutTraits, for uiView: UIViewType)
    
    /// Given a proposed size, returns the preferred size of the composite view.
    ///
    /// This method may be called more than once with different proposed sizes
    /// during the same layout pass. DanceUI views choose their own size, so one
    /// of the values returned from this function will always be used as the
    /// actual size of the composite view.
    ///
    /// - Parameters:
    ///   - proposal: The proposed size for the view.
    ///   - uiView: Your custom view object.
    ///   - context: A context structure containing information about the
    ///     current state of the system.
    ///
    /// - Returns: The composite size of the represented view controller.
    ///   Returning a value of `nil` indicates that the system should use the
    ///   default sizing algorithm.
    @MainActor @preconcurrency func sizeThatFits(_ proposal: ProposedViewSize, uiView: Self.UIViewType, context: Self.Context) -> CGSize?
    
}

@available(iOS 13.0, *)
extension UIViewRepresentable {
    
    /// Declares the content and behavior of this view.
    public var body: Body {
        bodyError()
    }
    
}

@available(iOS 13.0, *)
extension UIViewRepresentable {
    
    @_semantics("optimize.sil.specialize.generic.never")
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        typealias Adaptor = PlatformViewRepresentableAdaptor<Self>
        return Adaptor._makeView(view: view.unsafeBitCast(to: Adaptor.self), inputs: inputs)
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    public static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        typealias Adaptor = PlatformViewRepresentableAdaptor<Self>
        return Adaptor._makeViewList(view: view.unsafeBitCast(to: Adaptor.self), inputs: inputs)
    }
    
    public func _identifiedViewTree(in uiView: UIViewType) -> _IdentifiedViewTree {
        .empty
    }
    
    public func _overrideSizeThatFits(_ size: inout CGSize, in proposedSize: _ProposedSize, uiView: UIViewType) {
        _intentionallyLeftBlank()
    }
    
    public func _overrideLayoutTraits(_ layoutTraits: inout _LayoutTraits, for uiView: UIViewType) {
        _intentionallyLeftBlank()
    }
        
    /// Given a proposed size, returns the preferred size of the composite view.
    ///
    /// This method may be called more than once with different proposed sizes
    /// during the same layout pass. DanceUI views choose their own size, so one
    /// of the values returned from this function will always be used as the
    /// actual size of the composite view.
    ///
    /// - Parameters:
    ///   - proposal: The proposed size for the view.
    ///   - uiView: Your custom view object.
    ///   - context: A context structure containing information about the
    ///     current state of the system.
    ///
    /// - Returns: The composite size of the represented view controller.
    ///   Returning a value of `nil` indicates that the system should use the
    ///   default sizing algorithm.
    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: Self.UIViewType, context: Self.Context) -> CGSize? {
        nil
    }
}

@available(iOS 13.0, *)
extension UIViewRepresentable where Self.Coordinator == Void {

    /// Creates the custom instance that you use to communicate changes from
    /// your view to other parts of your DanceUI interface.
    ///
    /// Implement this method if changes to your view might affect other parts
    /// of your app. In your implementation, create a custom Swift instance that
    /// can communicate with other parts of your interface. For example, you
    /// might provide an instance that binds its variables to DanceUI
    /// properties, causing the two to remain synchronized. If your view doesn't
    /// interact with other parts of your app, providing a coordinator is
    /// unnecessary.
    ///
    /// DanceUI calls this method before calling the
    /// ``UIViewRepresentable/makeUIView(context:)`` method. The system provides
    /// your coordinator either directly or as part of a context structure when
    /// calling the other methods of your representable instance.
    public func makeCoordinator() -> Self.Coordinator {
        _intentionallyLeftBlank()
    }
}

@available(iOS 13.0, *)
extension UIViewRepresentable {

    /// Cleans up the presented UIKit view (and coordinator) in anticipation of
    /// their removal.
    ///
    /// Use this method to perform additional clean-up work related to your
    /// custom view. For example, you might use this method to remove observers
    /// or update other parts of your DanceUI interface.
    ///
    /// - Parameters:
    ///   - uiView: Your custom view object.
    ///   - coordinator: The custom coordinator instance you use to communicate
    ///     changes back to DanceUI. If you do not use a custom coordinator, the
    ///     system provides a default instance.
    public static func dismantleUIView(_ uiView: Self.UIViewType, coordinator: Self.Coordinator) {
        _intentionallyLeftBlank()
    }

}

@available(iOS 13.0, *)
public struct UIViewRepresentableContext<Representable: UIViewRepresentable> {
    
    /// The view's associated coordinator.
    public let coordinator: Representable.Coordinator

    /// The current transaction.
    public private(set) var transaction: Transaction

    /// The current `Environment`.
    public private(set) var environment: EnvironmentValues
    
    /// The current environment.
    ///
    /// Use the environment values to configure the state of your view when
    /// creating or updating it.
    internal weak var preferenceBridge: PreferenceBridge?
    
    @inline(__always)
    internal init(coordinator: Representable.Coordinator,
                  transaction: Transaction,
                  environment: EnvironmentValues,
                  preferenceBridge: PreferenceBridge?) {
        self.coordinator = coordinator
        self.transaction = transaction
        self.environment = environment
        self.preferenceBridge = preferenceBridge
    }
}
#if FEAT_HOSTING_VC_FOR_CELL
@available(iOS 13.0, *)
extension UIViewRepresentableContext {
    
    /// Gets the preference bridge as an `AnyObject` typed instance.
    ///
    /// There may be legacy UIKit components cannot have `_UIHostingView`'s
    /// added to view hierarchy before accessing its API. Once such a UIKit
    /// component wraps a `_UIHostingView`, the `_UIHostingView` may get
    /// incorrect preference bridge and cause a potential crash. For such kind
    /// of situation, you may grab this `anyPreferenceBridge` and wrap this
    /// preference bridge with `_UIHostingView._wrapPreferenceBridge`.
    public var anyPreferenceBridge: AnyObject? {
        return preferenceBridge
    }
    
}
#endif
