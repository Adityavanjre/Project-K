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

/// A view that represents a UIKit view controller.
///
/// Use a ``UIViewControllerRepresentable`` instance to create and manage a
/// <https://developer.apple.com/documentation/UIKit/UIViewController> object in your
/// DanceUI interface. Adopt this protocol in one of your app's custom
/// instances, and use its methods to create, update, and tear down your view
/// controller. The creation and update processes parallel the behavior of
/// DanceUI views, and you use them to configure your view controller with your
/// app's current state information. Use the teardown process to remove your
/// view controller cleanly from your DanceUI. For example, you might use the
/// teardown process to notify other objects that the view controller is
/// disappearing.
///
/// To add your view controller into your DanceUI interface, create your
/// ``UIViewControllerRepresentable`` instance and add it to your DanceUI
/// interface. The system calls the methods of your custom instance at
/// appropriate times.
///
/// The system doesn't automatically communicate changes occurring within your
/// view controller to other parts of your DanceUI interface. When you want your
/// view controller to coordinate with other DanceUI views, you must provide a
/// ``NSViewControllerRepresentable/Coordinator`` instance to facilitate those
/// interactions. For example, you use a coordinator to forward target-action
/// and delegate messages from your view controller to any DanceUI views.
@available(iOS 13.0, *)
public protocol UIViewControllerRepresentable : View where Self.Body == Never {
    
    /// The type of view controller to present.
    associatedtype UIViewControllerType : UIViewController
    
    /// Creates the view controller object and configures its initial state.
    ///
    /// You must implement this method and use it to create your view controller
    /// object. Create the view controller using your app's current data and
    /// contents of the `context` parameter. The system calls this method only
    /// once, when it creates your view controller for the first time. For all
    /// subsequent updates, the system calls the
    /// ``UIViewControllerRepresentable/updateUIViewController(_:context:)``
    /// method.
    ///
    /// - Parameter context: A context structure containing information about
    ///   the current state of the system.
    ///
    /// - Returns: Your UIKit view controller configured with the provided
    ///   information.
    @MainActor @preconcurrency func makeUIViewController(context: Self.Context) -> Self.UIViewControllerType
    
    /// Updates the state of the specified view controller with new information
    /// from DanceUI.
    ///
    /// When the state of your app changes, DanceUI updates the portions of your
    /// interface affected by those changes. DanceUI calls this method for any
    /// changes affecting the corresponding AppKit view controller. Use this
    /// method to update the configuration of your view controller to match the
    /// new state information provided in the `context` parameter.
    ///
    /// - Parameters:
    ///   - uiViewController: Your custom view controller object.
    ///   - context: A context structure containing information about the current
    ///     state of the system.
    @MainActor @preconcurrency func updateUIViewController(_ uiViewController: Self.UIViewControllerType, context: Self.Context)
    
    /// Cleans up the presented view controller (and coordinator) in
    /// anticipation of their removal.
    ///
    /// Use this method to perform additional clean-up work related to your
    /// custom view controller. For example, you might use this method to remove
    /// observers or update other parts of your DanceUI interface.
    ///
    /// - Parameters:
    ///   - uiViewController: Your custom view controller object.
    ///   - coordinator: The custom coordinator instance you use to communicate
    ///     changes back to DanceUI. If you do not use a custom coordinator, the
    ///     system provides a default instance.
    @MainActor @preconcurrency static func dismantleUIViewController(_ uiViewController: Self.UIViewControllerType, coordinator: Self.Coordinator)
    
    /// A type to coordinate with the view controller.
    associatedtype Coordinator = Void
    
    /// Creates the custom instance that you use to communicate changes from
    /// your view controller to other parts of your DanceUI interface.
    ///
    /// Implement this method if changes to your view controller might affect
    /// other parts of your app. In your implementation, create a custom Swift
    /// instance that can communicate with other parts of your interface. For
    /// example, you might provide an instance that binds its variables to
    /// DanceUI properties, causing the two to remain synchronized. If your view
    /// controller doesn't interact with other parts of your app, providing a
    /// coordinator is unnecessary.
    ///
    /// DanceUI calls this method before calling the
    /// ``UIViewControllerRepresentable/makeUIViewController(context:)`` method.
    /// The system provides your coordinator either directly or as part of a
    /// context structure when calling the other methods of your representable
    /// instance.
    @MainActor @preconcurrency func makeCoordinator() -> Self.Coordinator
    
    typealias Context = UIViewControllerRepresentableContext<Self>
    
    /// Given a proposed size, returns the preferred size of the composite view.
    ///
    /// This method may be called more than once with different proposed sizes
    /// during the same layout pass. DanceUI views choose their own size, so one
    /// of the values returned from this function will always be used as the
    /// actual size of the composite view.
    ///
    /// - Parameters:
    ///   - proposal: The proposed size for the view controller.
    ///   - uiViewController: Your custom view controller object.
    ///   - context: A context structure containing information about the
    ///     current state of the system.
    ///
    /// - Returns: The composite size of the represented view controller.
    ///   Returning a value of `nil` indicates that the system should use the
    ///   default sizing algorithm.
    @MainActor @preconcurrency func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: Self.UIViewControllerType, context: Self.Context) -> CGSize?
    
}

@available(iOS 13.0, *)
extension UIViewControllerRepresentable {
    
    public var body: Body {
        bodyError()
    }
    
}


@available(iOS 13.0, *)
extension UIViewControllerRepresentable where Self.Coordinator == Void {
    
    /// Creates the custom instance that you use to communicate changes from
    /// your view controller to other parts of your DanceUI interface.
    ///
    /// Implement this method if changes to your view controller might affect
    /// other parts of your app. In your implementation, create a custom Swift
    /// instance that can communicate with other parts of your interface. For
    /// example, you might provide an instance that binds its variables to
    /// DanceUI properties, causing the two to remain synchronized. If your view
    /// controller doesn't interact with other parts of your app, providing a
    /// coordinator is unnecessary.
    ///
    /// DanceUI calls this method before calling the
    /// ``UIViewControllerRepresentable/makeUIViewController(context:)`` method.
    /// The system provides your coordinator either directly or as part of a
    /// context structure when calling the other methods of your representable
    /// instance.
    public func makeCoordinator() -> Self.Coordinator {
		_intentionallyLeftBlank()
    }
	
}

@available(iOS 13.0, *)
extension UIViewControllerRepresentable {
    
    /// Cleans up the presented view controller (and coordinator) in
    /// anticipation of their removal.
    ///
    /// Use this method to perform additional clean-up work related to your
    /// custom view controller. For example, you might use this method to remove
    /// observers or update other parts of your DanceUI interface.
    ///
    /// - Parameters:
    ///   - uiViewController: Your custom view controller object.
    ///   - coordinator: The custom coordinator instance you use to communicate
    ///     changes back to DanceUI. If you do not use a custom coordinator, the
    ///     system provides a default instance.
    public static func dismantleUIViewController(_ uiViewController: UIViewControllerType, coordinator: Self.Coordinator) {
        
    }
	
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        typealias Adaptor = PlatformViewControllerRepresentableAdaptor<Self>
        return Adaptor._makeView(view: view.unsafeBitCast(to: Adaptor.self), inputs: inputs)
    }
    
    public static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        .unaryViewList(view: view, inputs: inputs)
    }
    
	public func _identifiedViewTree(in uiViewController: UIViewControllerType) -> _IdentifiedViewTree {
		.empty
	}
    
    public func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: Self.UIViewControllerType, context: Self.Context) -> CGSize? {
        nil
    }

}

/// Contextual information about the state of the system that you use to create
/// and update your UIKit view controller.
///
/// A ``UIViewControllerRepresentableContext`` structure contains details about
/// the current state of the system. When creating and updating your view
/// controller, the system creates one of these structures and passes it to the
/// appropriate method of your custom ``UIViewControllerRepresentable``
/// instance. Use the information in this structure to configure your view
/// controller. For example, use the provided environment values to configure
/// the appearance of your view controller and views. Don't create this
/// structure yourself.
@available(iOS 13.0, *)
public struct UIViewControllerRepresentableContext<Representable: UIViewControllerRepresentable> {
    
    /// The view's associated coordinator.
    public let coordinator: Representable.Coordinator

    /// The current `Transaction`.
    public var transaction: Transaction

    /// The current `Environment`.
    public var environment: EnvironmentValues

    /// This reference is weak to avoid retain cycles, as
    /// `UIViewControllerRepresentableContext` can escape to other places and
    /// the `_UIHostingView` related to `preferenceBridge` may be deallocated.
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
extension UIViewControllerRepresentableContext {
    
    /// Gets the preference bridge as an `AnyObject` typed instance.
    ///
    /// There may be legacy UIKit components cannot have `UIHostingController`'s
    /// view added to view hierarchy before accessing its view's API. Once such
    /// a UIKit component wraps a `UIHostingController`, the
    /// `UIHostingController` may get incorrect preference bridge and cause a
    /// potential crash. For such kind of situation, you may grab this
    /// `anyPreferenceBridge` and wrap this preference bridge with
    /// `UIHostingController._wrapPreferenceBridge`.
    public var anyPreferenceBridge: AnyObject? {
        return preferenceBridge
    }
    
}
#endif
