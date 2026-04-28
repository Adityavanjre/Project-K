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
internal protocol EventBindingSource: AnyObject {

    func `as`<A1>(_ otherType: A1.Type) -> A1?

    func attach(to bridge: EventBindingBridge)

    func didBind(to binding: EventBinding, id: EventID, in bridge: EventBindingBridge)

    func didUpdate(phase: GesturePhase<Void>, in bridge: EventBindingBridge)

    func didUpdate(gestureCategory: GestureCategory, in bridge: EventBindingBridge)

}

@available(iOS 13.0, *)
extension EventBindingSource {
    
    internal func `as`<A1>(_ otherType: A1.Type) -> A1? {
        nil
    }
    
    internal func didBind(to binding: EventBinding, id: EventID, in bridge: EventBindingBridge) {
        
    }
    
    internal func didUpdate(phase: GesturePhase<Void>, in bridge: EventBindingBridge) {
        
    }
    
    internal func didUpdate(gestureCategory: GestureCategory, in bridge: EventBindingBridge) {
        
    }
    
}

#if DEBUG
@available(iOS 13.0, *)
extension UIGestureRecognizer.State: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .began:
            return "\(_typeName(type(of: self))).began"
        case .changed:
            return "\(_typeName(type(of: self))).changed"
        case .ended:
            return "\(_typeName(type(of: self))).ended"
        case .possible:
            return "\(_typeName(type(of: self))).possible"
        case .failed:
            return "\(_typeName(type(of: self))).failed"
        case .cancelled:
            return "\(_typeName(type(of: self))).cancelled"
        @unknown default:
            _danceuiPreconditionFailure()
        }
    }
    
}
#endif

@available(iOS 13.0, *)
internal protocol EventBindingBridgeFactory {
    
    static func makeEventBindingBridge(bindingManager: EventBindingManager, responder: any AnyGestureResponder_FeatureGestureContainer) -> any EventBindingBridge & GestureGraphDelegate
}

@available(iOS 13.0, *)
internal struct EventBindingBridgeFactoryInput: ViewInput {
    
    internal static let defaultValue: (any EventBindingBridgeFactory.Type)? = nil
    
    internal typealias Value = (any EventBindingBridgeFactory.Type)?
}

// swift-format-ignore: NoBlockComments
@available(iOS 13.0, *)
extension _ViewInputs {
    
    internal func makeEventBindingBridge(bindingManager: EventBindingManager, responder: any AnyGestureResponder_FeatureGestureContainer) -> EventBindingBridge & GestureGraphDelegate {
        let bridge = UIKitResponderEventBindingBridge(eventBindingManager: bindingManager, responder: responder, gestureRecognizer: responder.gestureRecognizer)
        bindingManager.delegate = bridge
        return bridge
    }
    
}
