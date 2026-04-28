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

private var asyncImagelastIdentity: UInt32 = 0

/// ``AsyncImage`` load event information for tracking
///
/// When using ``AsyncImage`` to load images, you can receive callbacks when loading completes via ``View/onImageLoad(_:)`` modifier,
/// and get image loading info through ``AsyncImageLoadEvent``, commonly used for image loading tracking.
///
///     AsyncImage(url: URL(string: "https://example.com/icon.png")) { phase in
///         if let image = phase.image {
///             image // Displays the loaded image.
///         } else if phase.error != nil {
///             Color.red // Indicates an error.
///         } else {
///             Color.blue // Acts as a placeholder.
///         }
///     }
///     .onImageLoad { loadEvents in
///         loadEvents.forEach {
///             if $0.successed && ($0.event.from == .disk || $0.event.from == .network) {
///                 print("[AsyncImage] [LoadImage] load success: [from=\($0.event.from)] [URL=\($0.url?.absoluteString ?? "")]")
///             }
///             if !$0.successed && $0.event.from == .none {
///                 print("[AsyncImage] [LoadImage] load fail: [URL=\($0.url?.absoluteString ?? "")]")
///             }
///         }
///     }
///
@available(iOS 13.0, *)
public struct AsyncImageLoadEvent: Hashable {
    public static func == (lhs: AsyncImageLoadEvent, rhs: AsyncImageLoadEvent) -> Bool {
        lhs.identity == rhs.identity
    }
    
    public func hash(into hasher: inout Hasher) {
        identity.hash(into: &hasher)
    }
    
    /// URL of loaded image
    public var url: URL?
    
    internal var phaseContext: AsyncImagePhaseContext
    
    internal var isTriggered: Binding<Bool>
    
    internal var identity: Identity
    
    internal init(_ isTriggered: Binding<Bool>, url: URL?, phaseContext: AsyncImagePhaseContext, identity: Identity) {
        self.url = url
        self.phaseContext = phaseContext
        self.isTriggered = isTriggered
        self.identity = identity
    }
    
    internal func reset() {
        isTriggered.wrappedValue = false
    }
    
    internal var isEnabled: Bool {
        isTriggered.wrappedValue == true && identity.isValid
    }
    
    /// Tracking info for image loading
    public var event: AsyncImageEventContext {
        phaseContext.event
    }
    
    /// Image load completion status: success, failure
    public var phase: AsyncImagePhase {
        phaseContext.phase
    }
    
    /// Whether image loading succeeded
    public var successed: Bool {
        switch phase {
        case .success(_):
            return true
        default:
            return false
        }
    }
    
    /// ``PreferenceKey`` that triggers ``View/onImageLoad(_:)`` callback when ``AsyncImage`` completes loading
    /// ``View/onImageLoad(_:)`` receives callbacks when any ``AsyncImage`` in child Views completes loading,
    /// Passed ``AsyncImageLoadEvent``. Value of ``AsyncImageLoadEvent/Key`` is collection of ``AsyncImageLoadEvent``.
    public struct Key : PreferenceKey {
        
        @inline(__always)
        public static var defaultValue: Set<AsyncImageLoadEvent> { [] }
        
        public static func reduce(value: inout Value, nextValue: () -> Value) {
            value.formUnion(nextValue())
        }
    }
    
    internal struct Identity: Hashable {
        
        internal private(set) var value: UInt32
        
        @inline(__always)
        internal static var zero: Identity {
            Identity(value: 0)
        }
        
        @inlinable
        internal static func make() -> Identity {
            asyncImagelastIdentity &+= 1
            return Identity(value: asyncImagelastIdentity)
        }
        
        internal var isValid: Bool {
            value != 0
        }
        
    }
}

// Triggered when AsyncImage loading completes
@available(iOS 13.0, *)
internal struct AsyncImageTriggerModifier : ViewModifier {
    
    internal var loadEvent: AsyncImageLoadEvent
    
    internal func body(content: Content) -> some View {
        content.transformPreference(AsyncImageLoadEvent.Key.self) { value in
            guard loadEvent.isEnabled else {
                return
            }
            
            value.insert(loadEvent)
        }
    }
}

/// ``ViewModifier`` for ``AsyncImage`` load completion callback with image loading info
/// Corresponds to ``View/onImageLoad(_:)`` API
@available(iOS 13.0, *)
internal struct AsyncImageLoadedModifier : ViewModifier {
    
    internal let action: (Set<AsyncImageLoadEvent>) -> Void
    
    internal func body(content: Content) -> some View {
        content
            .onPreferenceChange(AsyncImageLoadEvent.Key.self) { value in
                let loadedEvent = value.filter {
                    $0.isEnabled
                }
                guard loadedEvent.count > 0 else {
                    return
                }
                action(loadedEvent)
                loadedEvent.forEach {
                    $0.reset()
                }
            }
    }
}


@available(iOS 13.0, *)
extension View {
    internal func imageTriggering(_ loadEvent: AsyncImageLoadEvent) -> some View {
        modifier(AsyncImageTriggerModifier(loadEvent: loadEvent))
    }
    
    /// Callback when ``AsyncImage`` completes loading, receives tracking info ``AsyncImageLoadEvent``.
    /// ``View/onImageLoad(_:)`` receives callbacks when any ``AsyncImage`` in child Views completes loading,
    /// Collection of passed ``AsyncImageLoadEvent``.
    ///
    /// When using ``AsyncImage`` to load images, you can receive callbacks when loading completes via ``View/onImageLoad(_:)`` modifier,
    /// and get image loading info through ``AsyncImageLoadEvent``, commonly used for image loading tracking.
    ///
    ///     AsyncImage(url: URL(string: "https://example.com/icon.png")) { phase in
    ///         if let image = phase.image {
    ///             image // Displays the loaded image.
    ///         } else if phase.error != nil {
    ///             Color.red // Indicates an error.
    ///         } else {
    ///             Color.blue // Acts as a placeholder.
    ///         }
    ///     }
    ///     .onImageLoad { loadEvents in
    ///         loadEvents.forEach {
    ///             if $0.successed && ($0.event.from == .disk || $0.event.from == .network) {
    ///                 print("[AsyncImage] [LoadImage] load success: [from=\($0.event.from)] [URL=\($0.url?.absoluteString ?? "")]")
    ///             }
    ///             if !$0.successed && $0.event.from == .none {
    ///                 print("[AsyncImage] [LoadImage] load fail: [URL=\($0.url?.absoluteString ?? "")]")
    ///             }
    ///         }
    ///     }
    ///
    public func onImageLoad(_ action: @escaping (Set<AsyncImageLoadEvent>) -> Void) -> some View {
        modifier(AsyncImageLoadedModifier(action: action))
    }
}
