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

/// A scrollable view.
///
/// The scroll view displays its content within the scrollable content region.
/// As the user performs platform-appropriate scroll gestures, the scroll view
/// adjusts what portion of the underlying content is visible. `ScrollView` can
/// scroll horizontally, vertically, or both, but does not provide zooming
/// functionality.
///
/// In the following example, a `ScrollView` allows the user to scroll through
/// a ``VStack`` containing 100 ``Text`` views. The image after the listing
/// shows the scroll view's temporarily visible scrollbar at the right; you can
/// disable it with the `showsIndicators` parameter of the `ScrollView`
/// initializer.
///
///     var body: some View {
///         ScrollView {
///             VStack(alignment: .leading) {
///                 ForEach(0..<100) {
///                     Text("Row \($0)")
///                 }
///             }
///         }
///     }
///
/// To perform programmatic scrolling, wrap one or more scroll views with a
/// ``ScrollViewReader``.

@available(iOS 13.0, *)
public struct ScrollView<Content> : View where Content : View {

    /// The scroll view's content.
    public var content: Content
    
    internal var configuration: ScrollViewConfiguration
    

    // Since DanceUI extends `ScrollView.id<T: Hashable>(_ id: T) -> IDView<ScrollView>`
    // by setting `id` and returning an `IDView` at the same time, we cannot
    // simply move `ScrollViewConfiguration.id` to
    // `ScrollViewConfiguration`.
    internal var id: AnyHashable?

    /// The scrollable axes of the scroll view.
    ///
    /// The default value is ``Axis/vertical``.
    public var axes: Axis.Set {
        get {
            configuration.axes
        }
        set {
            configuration.axes = newValue
        }
    }

    /// A value that indicates whether the scroll view displays the scrollable
    /// component of the content offset, in a way that's suitable for the
    /// platform.
    ///
    /// The default is `true`.
    public var showsIndicators: Bool {
        get {
            switch configuration.indicators {
            case .initial(let show):
                return show
            case .resolved(let s):
                switch configuration.axes {
                case .empty:
                    return false
                case .horizontal:
                    return s.horizontal.visibility.visible
                case .vertical:
                    return s.vertical.visibility.visible
                case .all:
                    return s.horizontal.visibility.visible &&
                    s.vertical.visibility.visible
                default:
                    return false
                }
            }
        }
        set {
            configuration.indicators = .initial(newValue)
        }
    }

    /// Creates a new instance that's scrollable in the direction of the given
    /// axis and can show indicators while scrolling.
    ///
    /// - Parameters:
    ///   - axes: The scroll view's scrollable axis. The default axis is the
    ///     vertical axis.
    ///   - showsIndicators: A Boolean value that indicates whether the scroll
    ///     view displays the scrollable component of the content offset, in a way
    ///     suitable for the platform. The default value for this parameter is
    ///     `true`.
    ///   - content: The view builder that creates the scrollable view.
    public init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ViewBuilder content: () -> Content) {
        self.init(
            content: content(),
            configuration: ScrollViewConfiguration(
                axes: axes, indicators: .initial(showsIndicators),
                bounceBehavior: ScrollViewConfiguration.ScrollBounces(
                    horizontal: .automatic, vertical: .automatic),
                isEnabled: true,
                isPagingEnabled: false,
                extendedConfigs: ScrollViewExtendedConfigs()
            )
        )
    }
    
    @inline(__always)
    internal init(content: Content, configuration: ScrollViewConfiguration) {
        self.content = content
        self.configuration = configuration
    }
    
    /// The content and behavior of the scroll view.
    public var body: some View {
        SystemScrollView(
            configuration: configuration,
            content: content.styleContext(ScrollViewStyleContext()),
            id: id
        )
    }
}

@available(iOS 13.0, *)
extension View {
    
    internal func styleContext<Context: StyleContext>(_: Context) -> some View {
        modifier(StyleContextWriter<Context>())
    }
    
}

@available(iOS 13.0, *)
extension ScrollView {
    
    public func id<ID: Hashable>(_ id: ID) -> some View {
        var copySelf = self
        copySelf.id = AnyHashable(id)
        return IDView(copySelf, id: id)
    }
    
}

@available(iOS 13.0, *)
extension ScrollIndicatorVisibility {
    
    fileprivate var visible: Bool {
        switch role {
        case .visible, .automatic:
            return true
        case .never, .hidden:
            return false
        }
    }
}
