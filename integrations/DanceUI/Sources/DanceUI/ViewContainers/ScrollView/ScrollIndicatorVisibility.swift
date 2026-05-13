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
extension View {

    /// Sets the visibility of scroll indicators within this view.
    ///
    /// Use this modifier to hide or show scroll indicators on scrollable
    /// content in views like a ``ScrollView``, ``List``, or ``TextEditor``.
    /// This modifier applies the preferred visibility to any
    /// scrollable content within a view hierarchy.
    ///
    ///     ScrollView {
    ///         VStack(alignment: .leading) {
    ///             ForEach(0..<100) {
    ///                 Text("Row \($0)")
    ///             }
    ///         }
    ///     }
    ///     .scrollIndicators(.hidden)
    ///
    /// Use the ``ScrollIndicatorVisibility/hidden`` value to indicate that you
    /// prefer that views never show scroll indicators along a given axis.
    /// Use ``ScrollIndicatorVisibility/visible`` when you prefer that
    /// views show scroll indicators. Depending on platform conventions,
    /// visible scroll indicators might only appear while scrolling. Pass
    /// ``ScrollIndicatorVisibility/automatic`` to allow views to
    /// decide whether or not to show their indicators.
    ///
    /// - Parameters:
    ///   - visibility: The visibility to apply to scrollable views.
    ///   - axes: The axes of scrollable views that the visibility applies to.
    ///
    /// - Returns: A view with the specified scroll indicator visibility.
    public func scrollIndicators(_ visibility: ScrollIndicatorVisibility, axes: Axis.Set = [.vertical, .horizontal]) -> some View {
        modifier(TransformScrollIndicators(visibility: visibility, options: .empty, axes: axes))
    }

}

/// The visibility of scroll indicators of a UI element.
///
/// Pass a value of this type to the ``View/scrollIndicators(_:axes:)`` method
/// to specify the preferred scroll indicator visibility of a view hierarchy.
@available(iOS 13.0, *)
public struct ScrollIndicatorVisibility: Equatable {

    internal var role: Role
    
    internal enum Role: Equatable {
        
        case automatic

        case visible

        case hidden

        case never

      }
    
    /// Scroll indicator visibility depends on the
    /// policies of the component accepting the visibility configuration.
    public static var automatic: ScrollIndicatorVisibility {
        ScrollIndicatorVisibility(role: .automatic)
    }

    /// Show the scroll indicators.
    public static var visible: ScrollIndicatorVisibility {
        ScrollIndicatorVisibility(role: .visible)
    }

    /// Hide the scroll indicators.
    public static var hidden: ScrollIndicatorVisibility {
        ScrollIndicatorVisibility(role: .hidden)
    }

    /// Scroll indicators should never be visible.
    ///
    /// This value behaves like ``hidden``, but
    /// overrides scrollable views that choose
    /// to keep their indidicators visible. When using this value,
    /// provide an alternative method of scrolling. The typical
    /// horizontal swipe gesture might not be available, depending on
    /// the current input device.
    public static var never: ScrollIndicatorVisibility {
        ScrollIndicatorVisibility(role: .never)
    }
    
}

@available(iOS 13.0, *)
private struct TransformScrollIndicators: ViewModifier {
    
    internal var visibility: ScrollIndicatorVisibility
    
    internal var options: ScrollIndicatorOptions
    
    internal var axes: Axis.Set
    
    fileprivate func body(content: Content) -> some View {
        content
            .transformEnvironment(\.horizontalScrollIndicatorConfiguration) { value in
                guard axes.contains(.horizontal) else {
                    return
                }
                value = ScrollIndicatorConfiguration(visibility: visibility, options: options)
            }
            .transformEnvironment(\.verticalScrollIndicatorConfiguration) { value in
                guard axes.contains(.vertical) else {
                    return
                }
                value = ScrollIndicatorConfiguration(visibility: visibility, options: options)
            }
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    internal var verticalScrollIndicatorConfiguration: ScrollIndicatorConfiguration {
        get {
            self[VerticalScrollIndicatorKey.self]
        }
        set {
            self[VerticalScrollIndicatorKey.self] = newValue
        }
    }

    internal var horizontalScrollIndicatorConfiguration: ScrollIndicatorConfiguration {
        get {
            self[HorizontalScrollIndicatorKey.self]
        }
        set {
            self[HorizontalScrollIndicatorKey.self] = newValue
        }
    }

    /// The visiblity to apply to scroll indicators of any
    /// vertically scrollable content.
    public var verticalScrollIndicatorVisibility: ScrollIndicatorVisibility {
        verticalScrollIndicatorConfiguration.visibility
    }

    /// The visibility to apply to scroll indicators of any
    /// horizontally scrollable content.
    public var horizontalScrollIndicatorVisibility: ScrollIndicatorVisibility {
        horizontalScrollIndicatorConfiguration.visibility
    }
    
}

@available(iOS 13.0, *)
private struct VerticalScrollIndicatorKey: EnvironmentKey {
    
    fileprivate typealias Value = ScrollIndicatorConfiguration

    fileprivate static var defaultValue: ScrollIndicatorConfiguration {
        ScrollIndicatorConfiguration(visibility: .automatic, options: .empty)
    }
    
}

@available(iOS 13.0, *)
private struct HorizontalScrollIndicatorKey: EnvironmentKey {
    
    fileprivate typealias Value = ScrollIndicatorConfiguration
    
    fileprivate static var defaultValue: ScrollIndicatorConfiguration {
        ScrollIndicatorConfiguration(visibility: .automatic, options: .empty)
    }
    
}

@available(iOS 13.0, *)
internal struct ScrollIndicatorConfiguration {

  internal var visibility: ScrollIndicatorVisibility

  internal var options: ScrollIndicatorOptions

}

@available(iOS 13.0, *)
// Unable to find the production and consumption of this structure.
// Not sure what the purpose of this structure is.
internal struct ScrollIndicatorOptions: OptionSet {

    internal let rawValue : Int
    
    internal static let empty: ScrollIndicatorOptions = []

}
