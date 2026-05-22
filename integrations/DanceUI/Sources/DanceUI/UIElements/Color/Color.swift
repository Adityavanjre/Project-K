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
import CoreGraphics
internal import DanceUIGraph
import MyShims

/// A representation of a color that adapts to a given context.
///
/// You can create a color in one of several ways:
///
/// * Load a color from an Asset Catalog:
///     ```
///     let aqua = Color("aqua") // Looks in your app's main bundle by default.
///     ```
/// * Specify component values, like red, green, and blue; hue,
///   saturation, and brightness; or white level:
///     ```
///     let skyBlue = Color(red: 0.4627, green: 0.8392, blue: 1.0)
///     let lemonYellow = Color(hue: 0.1639, saturation: 1, brightness: 1)
///     let steelGray = Color(white: 0.4745)
///     ```
/// * Create a color instance from another color, like a
///   <https://developer.apple.com/documentation/UIKit/UIColor> or an
///   <https://developer.apple.com/documentation/AppKit/NSColor>:
///     ```
///     #if os(iOS)
///     let linkColor = Color(uiColor: .link)
///     #elseif os(macOS)
///     let linkColor = Color(nsColor: .linkColor)
///     #endif
///     ```
/// * Use one of a palette of predefined colors, like ``ShapeStyle/black``,
///   ``ShapeStyle/green``, and ``ShapeStyle/purple``.
///
/// Some view modifiers can take a color as an argument. For example,
/// ``View/foregroundStyle(_:)`` uses the color you provide to set the
/// foreground color for view elements, like text or
/// [SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/):
///
///     Image(systemName: "leaf.fill")
///         .foregroundStyle(Color.green)
///
///
/// Because DanceUI treats colors as ``View`` instances, you can also
/// directly add them to a view hierarchy. For example, you can layer
/// a rectangle beneath a sun image using colors defined above:
///
///     ZStack {
///         skyBlue
///         Image(systemName: "sun.max.fill")
///             .foregroundStyle(lemonYellow)
///     }
///     .frame(width: 200, height: 100)
///
/// A color used as a view expands to fill all the space it's given,
/// as defined by the frame of the enclosing ``ZStack`` in the above example:
///
///
/// DanceUI only resolves a color to a concrete value
/// just before using it in a given environment.
/// This enables a context-dependent appearance for
/// system defined colors, or those that you load from an Asset Catalog.
/// For example, a color can have distinct light and dark variants
/// that the system chooses from at render time.
@frozen
@available(iOS 13.0, *)
public struct Color : Hashable, CustomStringConvertible {
    
    internal let _box: AnyColorBox
    
    @inline(__always)
    internal init<T: _ColorProvider>(provider: T) {
        _box = ColorBox(provider: provider)
    }
    
    /// A string that represents the contents of the environment values
    /// instance.
    public var description: String {
        _box.description
    }
}

@available(iOS 13.0, *)
extension Color {
    
    /// A profile that specifies how to interpret a color value for display.
    public enum RGBColorSpace: Hashable {
        case sRGB
        
        case sRGBLinear
        
        case displayP3
    }
    
    internal init(_ resolvedColor: Resolved) {
        self.init(provider: resolvedColor)
    }
    
    internal init(_ id: ContentStyle.ID) {
        switch id {
        case .primary:
            self = .primary
        case .secondary:
            self = .secondary
        case .tertiary:
            self = .tertiary
        case .quaternary:
            self = .quaternary
        case .quinary:
            _danceuiFatalError("ContentStyle.ID should not equal to .quinary")
        }
    }
    
    /// Returns a shading instance that fills with a color in the given
    /// color space.
    ///
    /// - Parameters:
    ///   - colorSpace: The RGB color space used to define the color. The
    ///     default is ``Color/RGBColorSpace/sRGB``.
    ///   - red: The red component of the color.
    ///   - green: The green component of the color.
    ///   - blue: The blue component of the color.
    ///   - opacity: The opacity of the color. The default is `1`, which
    ///     means fully opaque.
    /// - Returns: A shading instance filled with a color.
    public init(_ colorSpace: Color.RGBColorSpace = .sRGB, red: Double, green: Double, blue: Double, opacity: Double = 1) {
        let (redf, greenf, bluef, opacityf) = (Float(red), Float(green), Float(blue), Float(opacity))
        
        switch colorSpace {
        case .displayP3:
            self.init(provider: DisplayP3(red: redf, green: greenf, blue: bluef, alpha: opacityf))
        case .sRGB:
            let (linearRed, linearGreen, linearBlue) = (sRGBToLinear(redf), sRGBToLinear(greenf), sRGBToLinear(bluef))
            self.init(provider: Resolved(linearRed: linearRed, linearGreen: linearGreen, linearBlue: linearBlue, opacity: opacityf))
            break;
        case .sRGBLinear:
            self.init(provider: Resolved(linearRed: redf, linearGreen: greenf, linearBlue: bluef, opacity: opacityf))
        }
    }
    
    /// Returns a shading instance that fills with a monochrome color in
    /// the given color space.
    ///
    /// - Parameters:
    ///   - colorSpace: The RGB color space used to define the color. The
    ///     default is ``Color/RGBColorSpace/sRGB``.
    ///   - white: The value to use for each of the red, green, and blue
    ///     components of the color.
    ///   - opacity: The opacity of the color. The default is `1`, which
    ///     means fully opaque.
    /// - Returns: A shading instance filled with a color.
    public init(_ colorSpace: Color.RGBColorSpace = .sRGB, white: Double, opacity: Double = 1) {
        let (whitef, opacityf) = (Float(white), Float(opacity))
        
        switch colorSpace {
        case .displayP3:
            self.init(provider: DisplayP3(red: whitef, green: whitef, blue: whitef, alpha: opacityf))
        case .sRGB:
            let linearWhite = sRGBToLinear(whitef)
            self.init(provider: Resolved(linearRed: linearWhite, linearGreen: linearWhite, linearBlue: linearWhite, opacity: Float(opacity)))
            break;
        case .sRGBLinear:
            self.init(provider: Resolved(linearRed: whitef, linearGreen: whitef, linearBlue: whitef, opacity: opacityf))
        }
    }
    
    /// Creates a constant color from hue, saturation, and brightness values.
    ///
    /// This initializer creates a constant color that doesn't change based
    /// on context. For example, it doesn't have distinct light and dark
    /// appearances, unlike various system-defined colors, or a color that
    /// you load from an Asset Catalog with ``init(_:bundle:)``.
    ///
    /// - Parameters:
    ///   - hue: A value in the range `0` to `1` that maps to an angle
    ///     from 0° to 360° to represent a shade on the color wheel.
    ///   - saturation: A value in the range `0` to `1` that indicates
    ///     how strongly the hue affects the color. A value of `0` removes the
    ///     effect of the hue, resulting in gray. As the value increases,
    ///     the hue becomes more prominent.
    ///   - brightness: A value in the range `0` to `1` that indicates
    ///     how bright a color is. A value of `0` results in black, regardless
    ///     of the other components. The color lightens as you increase this
    ///     component.
    ///   - opacity: An optional degree of opacity, given in the range `0` to
    ///     `1`. A value of `0` means 100% transparency, while a value of `1`
    ///     means 100% opacity. The default is `1`.
    public init(hue: Double, saturation: Double, brightness: Double, opacity: Double = 1) {
        let (red, green, blue) = HSBToRGB(
            hue: hue,
            saturation: saturation,
            brightness: brightness
        )
        
        self.init(
            provider: Resolved(
                linearRed: sRGBToLinear(Float(red)),
                linearGreen: sRGBToLinear(Float(green)),
                linearBlue: sRGBToLinear(Float(blue)),
                opacity: Float(opacity)
            )
        )
    }
    
    internal struct DisplayP3: _ColorProvider {
        
        fileprivate static let p3ColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
        
        private var red: Float
        private var green: Float
        private var blue: Float
        private var alpha: Float
        
        internal init(red: Float, green: Float, blue: Float, alpha: Float) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
        
        internal func resolve(in environment: EnvironmentValues) -> Resolved {
            let colorTransform = DisplayP3.colorTransform
            
            var displayP3Color = (CGFloat(red), CGFloat(green), CGFloat(blue))
            var sRGBColor: (CGFloat, CGFloat, CGFloat) = (0, 0, 0)
            
            let displayP3ColorPtr = withUnsafeMutablePointer(
                to: &displayP3Color,
                {$0.withMemoryRebound(to: CGFloat.self, capacity: 3, {$0})}
            )
            
            let sRGBColorPtr = withUnsafeMutablePointer(
                to: &sRGBColor,
                {$0.withMemoryRebound(to: CGFloat.self, capacity: 3, {$0})}
            )
            
            MyCGColorTransformConvertColorComponents(
                colorTransform,
                DisplayP3.p3ColorSpace,
                0,
                displayP3ColorPtr,
                sRGBColorPtr
            )
            
            return Resolved(
                linearRed: Float(sRGBColor.0),
                linearGreen: Float(sRGBColor.1),
                linearBlue: Float(sRGBColor.2),
                opacity: alpha
            )
        }
        
        internal var staticColor: CGColor? {
            var displayP3Color = (CGFloat(red), CGFloat(green), CGFloat(blue), CGFloat(alpha))
            return CGColor(colorSpace: DisplayP3.p3ColorSpace, components: withUnsafePointer(
                to: &displayP3Color,
                {$0.withMemoryRebound(to: CGFloat.self, capacity: 4, {$0})}
            ))
        }
        
        internal func hash(into hasher: inout Hasher) {
            let ab = red.bitPattern
            let ab2 = ab & ~(0b1 << 0x3F)
            if ab2 != ab {
                hasher.combine(ab)
            } else {
                hasher.combine(ab2)
            }
        }
        
        fileprivate static let colorTransform: CGColorTransform = {
            let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
            return MyCGColorTransformCreate(colorSpace, 0)!
        }()
    }
}

@available(iOS 13.0, *)
extension Color {
    
    internal static var _backgroundColor: Color {
        return .init(provider: BackgroundColorProvider())
    }
    
    fileprivate struct BackgroundColorProvider: _ColorProvider {
        fileprivate func resolve(in environment: EnvironmentValues) -> Resolved {
            let backgroundInfo = environment.backgroundInfo
            let colorScheme = environment.colorScheme
            if colorScheme == .light {
                let backgroundContext = environment.backgroundContext
                var isGroupedOddTimes: Bool = (backgroundInfo.groupCount % 2) == 1
                if backgroundContext == .grouped {
                    isGroupedOddTimes.toggle()
                }
                if isGroupedOddTimes {
                    return .init(linearRed: Float(bitPattern: 0x3f5cf7e0), linearGreen: Float(bitPattern: 0x3f5cf7e0), linearBlue: Float(bitPattern: 0x3f6797e3), opacity: 1.0)
                } else {
                    return .init(linearRed: 1.0, linearGreen: 1.0, linearBlue: 1.0, opacity: 1.0)
                }
            } else {
                let layerCount = backgroundInfo.groupCount + backgroundInfo.layer
                switch layerCount {
                case 0: return .init(linearRed: 0.0, linearGreen: 0.0, linearBlue: 0.0, opacity: 1.0)
                case 1: return .init(linearRed: Float(bitPattern: 0x3c3e4149), linearGreen: Float(bitPattern: 0x3c3e4149), linearBlue: Float(bitPattern: 0x3c54b6c7), opacity: 1.0)
                case 2: return .init(linearRed: Float(bitPattern: 0x3cce54ad), linearGreen: Float(bitPattern: 0x3cce54ad), linearBlue: Float(bitPattern: 0x3cdfd010), opacity: 1.0)
                default: return .init(linearRed: Float(bitPattern: 0x3d2d4ebb), linearGreen: Float(bitPattern: 0x3d2d4ebb), linearBlue: Float(bitPattern: 0x3d39152b), opacity: 1.0) // 0x3d2d4ebb, 0x3d39152b
                }
            }
        }
        
        fileprivate var staticColor: CGColor? {
            nil
        }
        
        fileprivate static func == (lhs: BackgroundColorProvider, rhs: BackgroundColorProvider) -> Bool {
            return true
        }
    }
}

@available(iOS 13.0, *)
extension Color {
    
    /// A color that reflects the accent color of the system or app.
    ///
    /// The accent color is a broad theme color applied to
    /// views and controls. You can set it at the application level by specifying
    /// an accent color in your app's asset catalog.
    ///
    /// > Note: In macOS, DanceUI applies customization of the accent color
    /// only if the user chooses Multicolor under General > Accent color
    /// in System Preferences.
    ///
    /// The following code renders a ``Text`` view using the app's accent color:
    ///
    ///     Text("Accent Color")
    ///         .foregroundStyle(Color.accentColor)
    ///
    public static var accentColor: Color {
        return .init(provider: AccentColorProvider())
    }
    
    fileprivate struct AccentColorProvider: _ColorProvider {
        
        fileprivate func resolve(in environment: EnvironmentValues) -> Resolved {
            let activeColor = environment.accentColor ?? Color.blue
            
            let color: Color
            
            if let tintAdjustmentMode = environment.tintAdjustmentMode {
                switch tintAdjustmentMode {
                case .normal:
                    color = activeColor
                case .desaturated:
                    color = .init(provider: DesaturatedColor(color: activeColor))
                }
            } else {
                if !environment.isEnabled {
                    color = .init(provider: DesaturatedColor(color: activeColor))
                } else {
                    color = activeColor
                }
            }
            
            return color._box.resolve(in: environment)
        }
        
        fileprivate var staticColor: CGColor? {
            nil
        }
        
        fileprivate static func == (lhs: AccentColorProvider, rhs: AccentColorProvider) -> Bool {
            return true
        }
    }
}

@available(iOS 13.0, *)
extension Color {
    
    fileprivate struct DesaturatedColor: _ColorProvider {
        
        private let _color: Color
        
        @inline(__always)
        fileprivate init(color: Color) {
            _color = color
        }
        
        fileprivate func resolve(in environment: EnvironmentValues) -> Resolved {
            let resolvedColor = _color._box.resolve(in: environment)
            
            let a = resolvedColor.linearRed * 0.2126
            let b = resolvedColor.linearGreen * 0.7152
            let c = resolvedColor.linearBlue * 0.0722
            let g = a + b + c
            let d = resolvedColor.opacity * 0.8
            
            return Resolved(linearRed: g, linearGreen: g, linearBlue: g, opacity: d)
        }
        
        fileprivate var staticColor: CGColor? {
            nil
        }
    }
}

@available(iOS 13.0, *)
internal enum TintAdjustmentMode {
    
    case normal
    
    case desaturated
}

@available(iOS 13.0, *)
extension AnyShapeStyle {
    
    internal func fallbackColor(in environment: EnvironmentValues) -> Color? {
        var shapeStyleShape = _ShapeStyle_Shape(operation: .fallbackColor(0), 
                                                result: .none,
                                                environment: environment,
                                                role: .fill,
                                                inRecursiveStyle: false)
        self._apply(to: &shapeStyleShape)
        if case .color(let c) = shapeStyleShape.result {
            return c
        }
        return nil
    }
}

@available(iOS 13.0, *)
extension Color {
    
    fileprivate struct ForegroundColorProvider: _ColorProvider {
        
        fileprivate func resolve(in environment: EnvironmentValues) -> Resolved {
            let style = environment.effectiveForegroundStyle
            guard let resolved = style.fallbackColor(in: environment) else {
                return Color.primary.resolvePaint(in: environment)
            }
            return resolved.resolvePaint(in: environment)
        }
        
        fileprivate static func == (lhs: ForegroundColorProvider, rhs: ForegroundColorProvider) -> Bool {
            return true
        }
        
        fileprivate var staticColor: CGColor? {
            nil
        }
    }
}

@available(iOS 13.0, *)
extension Color {
    
    internal static var foreground: Color {
        Color(provider: ForegroundColorProvider())
    }
}

@available(iOS 13.0, *)
extension Color {
    /// A context-dependent red color suitable for use in UI elements.
    public static let red: Color = Color(provider: SystemColorType.red)
    
    /// A context-dependent orange color suitable for use in UI elements.
    public static let orange: Color = Color(provider: SystemColorType.orange)
    
    /// A context-dependent yellow color suitable for use in UI elements.
    public static let yellow: Color = Color(provider: SystemColorType.yellow)
    
    /// A context-dependent green color suitable for use in UI elements.
    public static let green: Color = Color(provider: SystemColorType.green)
    
    /// A context-dependent mint color suitable for use in UI elements.
    public static let mint: Color = Color(provider: SystemColorType.mint)
    
    /// A context-dependent teal color suitable for use in UI elements.
    public static let teal: Color = Color(provider: SystemColorType.teal)
    
    /// A context-dependent cyan color suitable for use in UI elements.
    public static let cyan: Color = Color(provider: SystemColorType.cyan)
    
    /// A context-dependent blue color suitable for use in UI elements.
    public static let blue: Color = Color(provider: SystemColorType.blue)
    
    /// A context-dependent indigo color suitable for use in UI elements.
    public static let indigo: Color = Color(provider: SystemColorType.indigo)
    
    /// A context-dependent purple color suitable for use in UI elements.
    public static let purple: Color = Color(provider: SystemColorType.purple)
    
    /// A context-dependent pink color suitable for use in UI elements.
    public static let pink: Color = Color(provider: SystemColorType.pink)
    
    /// A context-dependent brown color suitable for use in UI elements.
    public static let brown: Color = Color(provider: SystemColorType.brown)
    
    /// A white color suitable for use in UI elements.
    public static let white: Color = Color(Resolved(linearRed: 1.0, linearGreen: 1.0, linearBlue: 1.0, opacity: 1.0))
    
    /// A context-dependent gray color suitable for use in UI elements.
    public static let gray: Color = Color(provider: SystemColorType.gray)
    
    /// A black color suitable for use in UI elements.
    public static let black: Color = Color(Resolved(linearRed: 0.0, linearGreen: 0.0, linearBlue: 0.0, opacity: 1.0))
    
    /// A clear color suitable for use in UI elements.
    public static let clear: Color = Color(provider: Resolved())
    
    /// The color to use for primary content.
    public static let primary: Color = Color(provider: SystemColorType.primary)
    
    /// The color to use for secondary content.
    public static let secondary: Color = Color(provider: SystemColorType.secondary)
}

@available(iOS 13.0, *)
extension Color {
    
    internal static let tertiary: Color = Color(provider: SystemColorType.tertiary)
    
    internal static let quaternary: Color = Color(provider: SystemColorType.quaternary)
}

@available(iOS 13.0, *)
extension Color: View, ShapeStyle {
    
    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = Never
    
    public var body: Never {
        _terminatedViewNode()
    }
}

@available(iOS 13.0, *)
extension Color: Paint {
    
    internal func resolvePaint(in environment: EnvironmentValues) -> Resolved {
        self._box.resolve(in: environment)
    }
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        self._box.apply(color: self, to: &shape)
    }
}

@available(iOS 13.0, *)
extension Color {
    
    /// Creates a color from a color set that you indicate by name.
    ///
    /// Use this initializer to load a color from a color set stored in an
    /// Asset Catalog. The system determines which color within the set to use
    /// based on the environment at render time. For example, you
    /// can provide light and dark versions for background and foreground
    /// colors:
    ///
    ///
    /// You can then instantiate colors by referencing the names of the assets:
    ///
    ///     struct Hello: View {
    ///         var body: some View {
    ///             ZStack {
    ///                 Color("background")
    ///                 Text("Hello, world!")
    ///                     .foregroundStyle(Color("foreground"))
    ///             }
    ///             .frame(width: 200, height: 100)
    ///         }
    ///     }
    ///
    /// DanceUI renders the appropriate colors for each appearance:
    ///
    /// ![A side by side comparison of light and dark appearance screenshots
    ///   of the same content. The light variant shows dark text on a light
    ///   background, while the dark variant shows light text on a dark
    ///   background.](Color-init-2)
    ///
    /// - Parameters:
    ///   - name: The name of the color resource to look up.
    ///   - bundle: The bundle in which to search for the color resource.
    ///     If you don't indicate a bundle, the initializer looks in your app's
    ///     main bundle by default.
    public init(_ name: String, bundle: Bundle? = nil) {
        /// DanceUIAddition
#if DEBUG || DANCE_UI_INHOUSE
        checkColor(name, bundle: bundle)
#endif
        self = .init(provider: NamedColor(name: name, bundle: bundle))
    }
    
    public static var _mainNamedBundle: Bundle? {
        Bundle.main
    }
    
    fileprivate struct NamedColor: _ColorProvider {
        
        private let _name: String
        
        private let _bundle: Bundle?
        
        @inline(__always)
        fileprivate init(name: String, bundle: Bundle?) {
            _name = name
            _bundle = bundle
        }
        
        fileprivate func resolve(in environment: EnvironmentValues) -> Resolved {
            let bundle = self._bundle // ?? Color._mainNamedBundle
            guard let uiColor = UIColor(named: _name, in: bundle, compatibleWith: nil) else {
                // Error Log: 这里报 error 的话没办法体现在源码上，所以把检查逻辑放到了 Color.init 里面
                return resolveError(in: environment)
            }
            return uiColor.resolve(in: environment)
        }
        
        fileprivate var staticColor: CGColor? {
            nil
        }
        
        fileprivate func resolveError(in environment: EnvironmentValues) -> Resolved {
            UIColor.clear.resolve(in: environment)
        }
    }
}

#if DEBUG || DANCE_UI_INHOUSE
@available(iOS 13.0, *)
private func checkColor(_ name: String, bundle: Bundle?) {
    if UIColor(named: name, in: bundle, compatibleWith: nil) == nil {
        runtimeIssue(type: .warning, "No color named \"%@\" in asset catalog.", name)
    }
}
#endif
@available(iOS 13.0, *)
extension Color {
    /// Creates a color from a UIKit color.
    ///
    /// Use this method to create a DanceUI color from a
    /// <https://developer.apple.com/documentation/UIKit/UIColor> instance.
    /// The new color preserves the adaptability of the original.
    /// For example, you can create a rectangle using
    /// <https://developer.apple.com/documentation/UIKit/UIColor/3173132-link>
    /// to see how the shade adjusts to match the user's system settings:
    ///
    ///     struct Box: View {
    ///         var body: some View {
    ///             Color(UIColor.link)
    ///                 .frame(width: 200, height: 100)
    ///         }
    ///     }
    ///
    /// The `Box` view defined above automatically changes its
    /// appearance when the user turns on Dark Mode. With the light and dark
    /// appearances placed side by side, you can see the subtle difference
    /// in shades:
    ///
    /// ![A side by side comparison of light and dark appearance screenshots of
    ///   rectangles rendered with the link color. The light variant appears on
    ///   the left, and the dark variant on the right.](Color-init-3)
    ///
    /// > Note: Use this initializer only if you need to convert an existing
    /// <https://developer.apple.com/documentation/UIKit/UIColor> to a
    /// DanceUI color. Otherwise, create a DanceUI ``Color`` using an
    /// initializer like ``init(_:red:green:blue:opacity:)``, or use a system
    /// color like ``ShapeStyle/blue``.
    ///
    /// - Parameter color: A
    ///   <https://developer.apple.com/documentation/UIKit/UIColor> instance
    ///   from which to create a color.
    public init(_ color: UIColor) {
        self.init(provider: color)
    }
    
    /// Creates a color from a UIKit color.
    ///
    /// Use this method to create a DanceUI color from a
    /// <https://developer.apple.com/documentation/UIKit/UIColor> instance.
    /// The new color preserves the adaptability of the original.
    /// For example, you can create a rectangle using
    /// <https://developer.apple.com/documentation/UIKit/UIColor/3173132-link>
    /// to see how the shade adjusts to match the user's system settings:
    ///
    ///     struct Box: View {
    ///         var body: some View {
    ///             Color(uiColor: .link)
    ///                 .frame(width: 200, height: 100)
    ///         }
    ///     }
    ///
    /// The `Box` view defined above automatically changes its
    /// appearance when the user turns on Dark Mode. With the light and dark
    /// appearances placed side by side, you can see the subtle difference
    /// in shades:
    ///
    /// ![A side by side comparison of light and dark appearance screenshots of
    ///   rectangles rendered with the link color. The light variant appears on
    ///   the left, and the dark variant on the right.](Color-init-3)
    ///
    /// > Note: Use this initializer only if you need to convert an existing
    /// <https://developer.apple.com/documentation/UIKit/UIColor> to a
    /// DanceUI color. Otherwise, create a DanceUI ``Color`` using an
    /// initializer like ``init(_:red:green:blue:opacity:)``, or use a system
    /// color like ``ShapeStyle/blue``.
    ///
    /// - Parameter color: A
    ///   <https://developer.apple.com/documentation/UIKit/UIColor> instance
    ///   from which to create a color.
    /// Creates a color from an instance of `UIColor`.
    public init(uiColor: UIColor) {
        self.init(provider: uiColor)
    }
}

@available(iOS 13.0, *)
extension Color {
    
    /// Multiplies the opacity of the color by the given amount.
    ///
    /// - Parameter opacity: The amount by which to multiply the opacity of the
    ///   color.
    /// - Returns: A view with modified opacity.
    public func opacity(_ opacity: Double) -> Color {
        Color(provider: OpacityColor(color: self, opacity: opacity))
    }
    
    fileprivate struct OpacityColor: _ColorProvider {
        
        private let _color: Color
        
        private let _opacity: Double
        
        fileprivate init(color: Color, opacity: Double) {
            _color = color
            _opacity = opacity
        }
        
        fileprivate func resolve(in environment: EnvironmentValues) -> Resolved {
            let resolved = _color._box.resolve(in: environment)
            
            return Resolved(
                linearRed: resolved.linearRed,
                linearGreen: resolved.linearGreen,
                linearBlue: resolved.linearBlue,
                opacity: resolved.opacity * Float(_opacity)
            )
        }
        
        fileprivate var staticColor: CGColor? {
            _color._box.staticColor?.copy(alpha: _opacity)
        }
    }
}

@available(iOS 13.0, *)
extension Color: EnvironmentalView {
    
    internal func body(environment: EnvironmentValues) -> Color.Resolved {
        _box.resolve(in: environment)
    }
    
}

@available(iOS 13.0, *)
// MARK: - Supporing Types

// MARK: - Resolved
extension Color {
    
    @_spi(DanceUICompose)
    public struct Resolved: _ColorProvider,
                               Animatable,
                               ContentResponder,
                               PrimitiveView,
                               _RendererLeafView,
                               ResolvedPaint,
                               Hashable
    {
        @_spi(DanceUICompose)
        public static func _makeView(view: _GraphValue<Color.Resolved>, inputs: _ViewInputs) -> _ViewOutputs {
            var animatableView = view
            _makeAnimatable(value: &animatableView, inputs: inputs.base)
            return _makeLeafView(view: animatableView, inputs: inputs)
        }
        
        @_spi(DanceUICompose)
        public var animatableData: AnimatablePair<Float, AnimatablePair<Float, AnimatablePair<Float, Float>>> {
            get {
                .init(linearRed * 128.0, .init(linearGreen * 128.0, .init(linearBlue * 128.0, alpha * 128.0)))
            }
            set {
                (linearRed, linearGreen, linearBlue, opacity) = (
                    newValue.first,
                    newValue.second.first,
                    newValue.second.second.first,
                    newValue.second.second.second
                )
                linearRed   *= 0.0078125
                linearGreen *= 0.0078125
                linearBlue  *= 0.0078125
                opacity     *= 0.0078125
            }
        }
        
        public typealias AnimatableData = AnimatablePair<Float, AnimatablePair<Float, AnimatablePair<Float, Float>>>
        
        public var linearRed: Float

        public var linearGreen: Float

        public var linearBlue: Float

        public var opacity: Float
        
        internal var red: Float {
            linearToSRGB(linearRed)
        }
        
        internal var green: Float {
            linearToSRGB(linearGreen)
        }
        
        internal var blue: Float {
            linearToSRGB(linearBlue)
        }
        
        internal var alpha: Float {
            opacity
        }
        
        internal var white: Resolved {
            .init(linearRed: 1, linearGreen: 1, linearBlue: 1, opacity: 1)
        }
        
        internal var black: Resolved {
            .init(linearRed: 0, linearGreen: 0, linearBlue: 0, opacity: 1)
        }
        
        internal static var empty: Resolved {
            .init(linearRed: 0, linearGreen: 0, linearBlue: 0, opacity: 0)
        }
        
        @usableFromInline
        internal init(
            linearRed: Float,
            linearGreen: Float,
            linearBlue: Float,
            opacity: Float
        ) {
            self.linearRed = linearRed
            self.linearGreen = linearGreen
            self.linearBlue = linearBlue
            self.opacity = opacity
        }
        
        @usableFromInline
        internal init() {
            (linearRed, linearGreen, linearBlue, opacity) = (0, 0, 0, 0)
        }
        
        @inlinable
        @_spi(DanceUICompose)
        public init?(_ uiColor: UIColor) {
            var (red, green, blue, alpha): (CGFloat, CGFloat, CGFloat, CGFloat)
            = (0, 0, 0, 0)
            
            if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                
                let (linearRed, linearGreen, linearBlue) = (
                    sRGBToLinear(Float(red)),
                    sRGBToLinear(Float(green)),
                    sRGBToLinear(Float(blue))
                )
                
                self.init(
                    linearRed: linearRed,
                    linearGreen: linearGreen,
                    linearBlue: linearBlue,
                    opacity: Float(alpha)
                )
                
            } else {
                return nil
            }
        }
        
        @inlinable
        internal init?(failableCGColor cgColor: CGColor) {
            guard let color = cgColor.converted(
                to: Resolved.colorSpace,
                intent: .defaultIntent,
                options: nil
            ) else {
                return nil
            }
            
            guard let components = color.components else {
                return nil
            }
            let red = components[0]
            let green = components[1]
            let blue = components[2]
            let alpha = cgColor.alpha
            
            let (linearRed, linearGreen, linearBlue) = (
                sRGBToLinear(Float(red)),
                sRGBToLinear(Float(green)),
                sRGBToLinear(Float(blue))
            )
            
            self.init(
                linearRed: linearRed,
                linearGreen: linearGreen,
                linearBlue: linearBlue,
                opacity: Float(alpha)
            )
        }
        
        @inlinable
        internal init(cgColor: CGColor) {
            let color = cgColor.converted(
                to: Resolved.colorSpace,
                intent: .defaultIntent,
                options: nil
            )!
            
            let components = color.components!
            let red = components[0]
            let green = components[1]
            let blue = components[2]
            let alpha = cgColor.alpha
            
            let (linearRed, linearGreen, linearBlue) = (
                sRGBToLinear(Float(red)),
                sRGBToLinear(Float(green)),
                sRGBToLinear(Float(blue))
            )
            
            self.init(
                linearRed: linearRed,
                linearGreen: linearGreen,
                linearBlue: linearBlue,
                opacity: Float(alpha)
            )
        }
        
        @_spi(DanceUICompose)
        public static let colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.extendedSRGB)!
        
        @inlinable
        internal func resolve(in environment: EnvironmentValues) -> Resolved {
            self
        }
        
        internal var staticColor: CGColor? {
            self.cgColor
        }
        
        internal static var animatesSize: Bool { true }
        
        internal func content() -> DisplayList.Content.Value {
            .color(self)
        }
        
        internal func contains(points: [CGPoint], size: CGSize) -> BitVector64 {
            // The original `contains(points:, size:)` is now
            // `contains(points:, size:, edgeInsets:)`. This interface is
            // remained because current.patch exposes it in back-delpoyable
            // release mode.
            contains(points: points, size: size, edgeInsets: .zero)
        }
        
        internal func contains(points: [CGPoint], size: CGSize, edgeInsets: EdgeInsets) -> BitVector64 {
            guard opacity > 0 else {
                return BitVector64()
            }
            
            let insetRect = CGRect(origin: .zero, size: size).inset(by: edgeInsets)
            
            return BitVector64().contained(points: points) { point in
                insetRect.has(point)
            }
        }
        
        @_spi(DanceUICompose)
        public func fill(_ path: Path, style: FillStyle, in graphicsContext: GraphicsContext, bounds: CGRect?) {
            graphicsContext.fill(path, with: .color(self), style: style)
        }
        
        @_spi(DanceUICompose)
        public var isClear: Bool {
            opacity == 0
        }
        
        @_spi(DanceUICompose)
        public var isOpaque: Bool {
            opacity == 1
        }
        
        internal var colorDescription: String {
            if self == black {
                return "black"
            } else if self == Self.empty {
                return "clear"
            } else if self == white {
                return "white"
            } else {
                return description
            }
        }
        
        internal var description: String {
            String(
                format: "#%02X%02X%02X%02X",
                Int(red * 255.0 + 0.5),
                Int(green * 255.0 + 0.5),
                Int(blue * 255.0 + 0.5),
                Int(opacity * 255.0 + 0.5)
            )
        }
    }
}

/// Describes the working color space for color-compositing operations
/// and the range of color values that are guaranteed to be preserved.
@available(iOS 13.0, *)
public enum ColorRenderingMode: Hashable {
    
    /// The non-linear sRGB (i.e. gamma corrected) working color space.
    /// Color component values outside the range [0, 1] have undefined
    /// results.
    case nonLinear
    
    /// The linear sRGB (i.e. not gamma corrected) working color space.
    /// Color component values outside the range [0, 1] have undefined
    /// results.
    case linear
    
    /// The linear sRGB (i.e. not gamma corrected) working color space.
    /// Color component values outside the range [0, 1] are preserved.
    case extendedLinear
}

/// The ColorScheme enumerates the user setting options for Light or Dark Mode
/// and also the light/dark setting for any particular view when the app
/// wants to override the user setting.
@available(iOS 13.0, *)
public enum ColorScheme : Hashable, CaseIterable {
    
    case light
    
    case dark
}

#if os(iOS) || os(tvOS)
import UIKit

@available(iOS 13.0, *)
extension ColorScheme {
    
    internal init(_ userInterfaceStyle: UIUserInterfaceStyle) {
        switch userInterfaceStyle {
        case .dark:     self = .dark
        default:        self = .light
        }
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Sets this view's color scheme.
    ///
    /// Use `colorScheme(_:)` to set the color scheme for the view to which you
    /// apply it and any subviews. If you want to set the color scheme for all
    /// views in the presentation, use ``View/preferredColorScheme(_:)``
    /// instead.
    ///
    /// - Parameter colorScheme: The color scheme for this view.
    ///
    /// - Returns: A view that sets this view's color scheme.
    @inlinable
    public func colorScheme(_ colorScheme: ColorScheme) -> some View {
        environment(\.colorScheme, colorScheme)
    }
}

@available(iOS 13.0, *)
extension UIUserInterfaceStyle {
    
    internal init(_ colorScheme: ColorScheme) {
        switch colorScheme {
        case .dark:     self = .dark
        case .light:    self = .light
        }
    }
    
    internal init(_ colorScheme: ColorScheme?) {
        guard let colorScheme = colorScheme else {
            self = .unspecified
            return
        }
        self.init(colorScheme)
    }
}

@available(iOS 13.0, *)
extension UIStatusBarStyle {
    
    @inline(__always)
    internal init(_ colorScheme: ColorScheme) {
        switch colorScheme {
        case .light:
            self = .default
        case .dark:
            self = .lightContent
        }
    }
}

#endif
/// The ColorSchemeContrast enumerates the Increase Contrast user setting
/// options. The user's choice cannot be overridden by the app.
@available(iOS 13.0, *)
public enum ColorSchemeContrast : Hashable, CaseIterable {
    
    case standard
    
    case increased
}

#if os(iOS) || os(tvOS)
import UIKit

@available(iOS 13.0, *)
extension ColorSchemeContrast {
    
    /// Create a contrast from its UIAccessibilityContrast equivalent.
    @available(iOS 13.0, tvOS 13.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    public init?(_ uiAccessibilityContrast: UIAccessibilityContrast) {
        switch uiAccessibilityContrast {
        case .normal:       self = .standard
        case .high:         self = .increased
        default:            return nil
        }
    }
    
}


@available(iOS 13.0, *)
@available(macOS, unavailable)
@available(watchOS, unavailable)
extension UIAccessibilityContrast {
    
    /// Create a contrast from its ColorSchemeContrast equivalent.
    public init(_ colorSchemeContrast: ColorSchemeContrast?) {
        switch colorSchemeContrast {
        case .standard:
            self = .normal
        case .increased:
            self = .high
        case .none:
            self = .unspecified
        }
    }
}

#endif


@usableFromInline
@available(iOS 13.0, *)
internal class AnyColorBox: AnyShapeStyleBox, _ColorProvider, CustomStringConvertible {
    
    internal func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        _abstract(self)
    }
    
    internal var staticColor: CGColor? {
        _abstract(self)
    }
    
    @usableFromInline
    internal static func == (lhs: AnyColorBox, rhs: AnyColorBox) -> Bool {
        return lhs.isEqual(to: rhs)
    }
    
    @usableFromInline
    internal func hash(into hasher: inout Hasher) {
        _abstract(self)
    }
    
    internal func isEqual(to another: AnyColorBox) -> Bool {
        _abstract(self)
    }
    
    @usableFromInline
    internal var description: String {
        _abstract(self)
    }
    
    internal override func apply(to: inout _ShapeStyle_Shape) {
        super.apply(to: &to)
    }
    
    internal func apply(color: Color, to: inout _ShapeStyle_Shape) {
        _abstract(self)
    }
}


@available(iOS 13.0, *)
internal final class ColorBox<P: _ColorProvider>: AnyColorBox {
    
    internal typealias Provider = P
    
    private let _provider: Provider
    
    internal init(provider: Provider) {
        _provider = provider
    }
    
    internal override func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        _provider.resolve(in: environment)
    }
    
    internal override var staticColor: CGColor? {
        _provider.staticColor
    }
    
    internal override func isEqual(to another: AnyColorBox) -> Bool {
        if let ColorBox = another as? ColorBox {
            return ColorBox._provider == _provider
        }
        return false
    }
    
    internal override func hash(into hasher: inout Hasher) {
        _provider.hash(into: &hasher)
    }
    
    internal override var description: String {
        _provider.colorDescription
    }
    
    internal override func apply(color: Color, to: inout _ShapeStyle_Shape) {
        _provider.apply(color: color, to: &to)
    }
}

@available(iOS 13.0, *)
internal protocol _ColorProvider: Hashable {
    
    func resolve(in environment: EnvironmentValues) -> Color.Resolved
    
    func apply(color: Color, to: inout _ShapeStyle_Shape)
    
    var staticColor: CGColor? { get }
    
    var colorDescription: String { get }
}

@available(iOS 13.0, *)
extension _ColorProvider {
    
    internal var colorDescription: String {
        String(describing: self)
    }
    
    internal func apply(color: Color, to: inout _ShapeStyle_Shape) {
        _apply(color: color, to: &to)
    }
    
    internal func _apply(color: Color, to shape: inout _ShapeStyle_Shape) {
        switch shape.operation {
        case .prepare((let text, let level)):
            if level == 0 {
                let newText = text.foregroundColor(color)
                shape.result = .prepared(newText)
            } else {
                let enviorments = shape.environment
                let opacity = enviorments.colorOpacity(with: level)
                let newColor = color.opacity(Double(opacity))
                let newText = text.foregroundColor(newColor)
                shape.result = .prepared(newText)
            }
        case .resolveStyle(let range):
            guard !range.isEmpty else {
                return
            }
            
            let enviornment = shape.environment
            let environmentOpacity = enviornment.colorOpacity(with: range.lowerBound)
            var colorResolved = self.resolve(in: shape.environment)
            colorResolved.opacity *= environmentOpacity
            shape.result = .resolved(.color(colorResolved))
        case .fallbackColor(let value):
            guard value > 0 else {
                shape.result = .color(color)
                return
            }
            let enviornment = shape.environment
            let environmentOpacity = enviornment.colorOpacity(with: value)
            let newColor = color.opacity(Double(environmentOpacity))
            shape.result = .color(newColor)
        case .multiLevel,
             .primaryStyle:
            break
        }
    }
}

@available(iOS 13.0, *)
internal enum SystemColorType: _ColorProvider {

    case red

    case orange

    case yellow

    case green

    case teal

    case mint

    case cyan

    case blue

    case indigo

    case purple

    case pink

    case brown

    case gray

    case primary

    case secondary

    case tertiary

    case quaternary

    case quinary

    case primaryFill

    case secondaryFill

    case tertiaryFill

    case quaternaryFill
    
    internal init(_ id: ContentStyle.ID) {
        switch id {
        case .primary:
            self = .primary
        case .secondary:
            self = .secondary
        case .tertiary:
            self = .tertiary
        case .quaternary:
            self = .quaternary
        case .quinary:
            self = .quinary
        }
    }
    
    internal func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        environment.systemColorDefinition.value(for: self, environment: environment)
    }
    
    internal var staticColor: CGColor? {
        nil
    }
    
    internal func apply(color: Color, to: inout _ShapeStyle_Shape) {
        switch self {
        case .primary:
            let legacyStyle = LegacyContentStyle(id: .primary, color: color)
            legacyStyle._apply(to: &to)
        case .secondary:
            let legacyStyle = LegacyContentStyle(id: .secondary, color: color)
            legacyStyle._apply(to: &to)
        case .tertiary:
            let legacyStyle = LegacyContentStyle(id: .tertiary, color: color)
            legacyStyle._apply(to: &to)
        case .quaternary:
            let legacyStyle = LegacyContentStyle(id: .quaternary, color: color)
            legacyStyle._apply(to: &to)
        case .quinary:
            let legacyStyle = LegacyContentStyle(id: .quinary, color: color)
            legacyStyle._apply(to: &to)
        default:
            _apply(color: color, to: &to)
        }
    }
}

@available(iOS 13.0, *)
internal protocol SystemColorDefinition {
    
    static func value(for systemColorType: SystemColorType, environment: EnvironmentValues) -> Color.Resolved
    
    static func opacity(at: Int, environment: EnvironmentValues) -> Float
}

@available(iOS 13.0, *)
internal struct DefaultSystemColorDefinition: SystemColorDefinition {
    
    internal static func opacity(at levels: Int, environment: EnvironmentValues) -> Float {
        let contentStyleID = ContentStyle.ID(truncatingLevel: levels)
        switch contentStyleID {
        case .primary:
            return 1
        case .secondary:
            return 0.5
        case .tertiary:
            return 0.25
        case .quaternary:
            return 0.18
        case .quinary:
            return 0.07
        }
    }
    
    internal static func value(for systemColorType: SystemColorType, environment: EnvironmentValues) -> Color.Resolved {
        let scheme = environment.colorScheme
        
        let contrast = environment.colorSchemeContrast
        
        let r: Float
        let g: Float
        let b: Float
        let a: Float
        
        switch scheme {
        case .light:
            switch (systemColorType, contrast) {
            case (.red, .standard):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3d332380, 0x3cf2212c, 0x3f800000).toFloat // (1, 0_00749903, 0_0295568, 1)
            case (.red, .increased):
                (r, g, b, a) = _FourInt(0x3f2df681, 0x0, 0x3bf5ba70, 0x3f800000).toFloat // (0_679543, 0, 0_00749903, 1)
            case (.orange, .standard):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3e99e0e2, 0x0, 0x3f800000).toFloat // (1, 0_300544, 0, 1)
            case (.orange, .increased):
                (r, g, b, a) = _FourInt(0x3f15862b, 0x3d0ca7e4, 0x0, 0x3f800000).toFloat // (0_584078, 0_0343398, 0, 1)
            case (.yellow, .standard):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3f1a946f, 0x0, 0x3f800000).toFloat // (1, 0_603827, 0, 1)
            case (.yellow, .increased):
                (r, g, b, a) = _FourInt(0x3ee3f16b, 0x3da44a4b, 0x0, 0x3f800000).toFloat // (0_445201, 0_0802198, 0, 1)
            case (.green, .standard):
                (r, g, b, a) = _FourInt(0x3d0ca7e4, 0x3f12353e, 0x3dcc97b4, 0x3f800000).toFloat // (0_0343398, 0_571125, 0_0998987, 1)
            case (.green, .increased):
                (r, g, b, a) = _FourInt(0x3c9085db, 0x3e82203c, 0x3d3f23e3, 0x3f800000).toFloat // (0_017642, 0_254152, 0_0466651, 1)
            case (.teal, .standard):
                (r, g, b, a) = _FourInt(0x3cf2212c, 0x3ede4965, 0x3f12353e, 0x3f800000).toFloat // (0_0295568, 0_434154, 0_571125, 1)
            case (.teal, .increased):
                (r, g, b, a) = _FourInt(0x0, 0x3e6495e0, 0x3ea31892, 0x3f800000).toFloat // (0, 0_223228, 0_318547, 1)
            case (.mint, .standard):
                (r, g, b, a) = _FourInt(0x0, 0x3f12353e, 0x3f03d1a7, 0x3f800000).toFloat // (0, 0_571125, 0_514918, 1)
            case (.mint, .increased):
                (r, g, b, a) = _FourInt(0x3b70f18d, 0x3e60cb7c, 0x3e4ad2b1, 0x3f800000).toFloat // (0_00367651, 0_219526, 0_198069, 1)
            case (.cyan, .standard):
                (r, g, b, a) = _FourInt(0x3d02a569, 0x3ed5f50b, 0x3f4a9282, 0x3f800000).toFloat // (0_031896, 0_417885, 0_791298, 1)
            case (.cyan, .increased):
                (r, g, b, a) = _FourInt(0x0, 0x3e29186a, 0x3ebe12e1, 0x3f800000).toFloat // (0, 0_165132, 0_417885, 1)
            case (.blue, .standard):
                (r, g, b, a) = _FourInt(0x0, 0x3e4749e8, 0x3f800000, 0x3f800000).toFloat // (0, 0_194618, 1, 1)
            case (.blue, .increased):
                (r, g, b, a) = _FourInt(0x0, 0x3d51ffef, 0x3f391a26, 0x3f800000).toFloat // (0, 0_0512695, 0_723055, 1)
            case (.indigo, .standard):
                (r, g, b, a) = _FourInt(0x3dc7dbe0, 0x3dbe95b3, 0x3f2c253f, 0x3f800000).toFloat // (0_0975873, 0_093059, 0_672443, 1)
            case (.indigo, .increased):
                (r, g, b, a) = _FourInt(0x3d171965, 0x3d0ca7e4, 0x3ebb8579, 0x3f800000).toFloat // (0_0368895, 0_0343398, 0_366253, 1)
            case (.purple, .standard):
                (r, g, b, a) = _FourInt(0x3edb7d54, 0x3daccd70, 0x3f3aff7c, 0x3f800000).toFloat // (0_428691, 0_0843762, 0_730461, 1)
            case (.purple, .increased):
                (r, g, b, a) = _FourInt(0x3e8014c2, 0x3d6cc564, 0x3ed081cd, 0x3f800000).toFloat // (0_250158, 0_0578054, 0_40724, 1)
            case (.pink, .standard):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3cd6f7d5, 0x3dba0b38, 0x3f800000).toFloat // (1, 0_0262412, 0_0908417, 1)
            case (.pink, .increased):
                (r, g, b, a) = _FourInt(0x3f26c286, 0x3b9c87fd, 0x3d73c20f, 0x3f800000).toFloat // (0_651406, 0_00477695, 0_0595112, 1)
            case (.brown, .standard):
                (r, g, b, a) = _FourInt(0x3eb8fd37, 0x3e6c4720, 0x3de53cd5, 0x3f800000).toFloat // (0_361307, 0_23074, 0_111932, 1)
            case (.brown, .increased):
                (r, g, b, a) = _FourInt(0x3e595307, 0x3e05427f, 0x3d73c20f, 0x3f800000).toFloat // (0_212231, 0_130136, 0_0595112, 1)
            case (.gray, .standard):
                (r, g, b, a) = _FourInt(0x3e8a7eb2, 0x3e8a7eb2, 0x3e9562f8, 0x3f800000).toFloat // (0_270498, 0_270498, 0_291771, 1)
            case (.gray, .increased):
                (r, g, b, a) = _FourInt(0x3e198f10, 0x3e198f10, 0x3e25eb07, 0x3f800000).toFloat // (0_14996, 0_14996, 0_162029, 1)
            case (.primary, _):
                (r, g, b, a) = _FourInt(0, 0, 0, 0x3f800000).toFloat // (0, 0, 0, 1)
            case (.secondary, .standard):
                (r, g, b, a) = _FourInt(0x3d39152b, 0x3d39152b, 0x3d65e6fe, 0x3f199999).toFloat // (0_0451862, 0_0451862, 0_0561285, 0_6)
            case (.secondary, .increased):
                (r, g, b, a) = _FourInt(0x3d39152b, 0x3d39152b, 0x3d65e6fe, 0x3f4ccccc).toFloat // (0_0451862, 0_0451862, 0_0561285, 0_8)
            case (.tertiary, .standard):
                (r, g, b, a) = _FourInt(0x3d39152b, 0x3d39152b, 0x3d65e6fe, 0x3e999999).toFloat // (0_0451862, 0_0451862, 0_0561285, 0_3)
            case (.tertiary, .increased):
                (r, g, b, a) = _FourInt(0x3d39152b, 0x3d39152b, 0x3d65e6fe, 0x3f333333).toFloat // (0_0451862, 0_0451862, 0_0561285, 0_7)
            case (.quaternary, .standard):
                (r, g, b, a) = _FourInt(0x3d39152b, 0x3d39152b, 0x3d65e6fe, 0x3e3851eb).toFloat // (0_0451862, 0_0451862, 0_0561285, 0_18)
            case (.quaternary, .increased):
                (r, g, b, a) = _FourInt(0x3d39152b, 0x3d39152b, 0x3d65e6fe, 0x3f0ccccd).toFloat // (0_0451862, 0_0451862, 0_0561285, 0_55)
            case (.quinary, .standard):
                (r, g, b, a) = _FourInt(0x0, 0x0, 0x0, 0x3d4ccccd).toFloat // (0, 0, 0, 0_05)
            case (.quinary, .increased):
                (r, g, b, a) = _FourInt(0x0, 0x0, 0x0, 0x3da6a6a7).toFloat // (0, 0, 0, 0_0813726)
            case (.primaryFill, .standard):
                (r, g, b, a) = _FourInt(0x3e405416, 0x3e405416, 0x3e5d0a8b, 0x3d4ccccd).toFloat // (0_187821, 0_187821, 0_215861, 0_05)
            case (.primaryFill, .increased):
                (r, g, b, a) = _FourInt(0x3e405416, 0x3e405416, 0x3e5d0a8b, 0x3da6a6a7).toFloat // (0_187821, 0_187821, 0_215861, 0_0813726)
            case (.secondaryFill, .standard):
                (r, g, b, a) = _FourInt(0x3e405416, 0x3e405416, 0x3e5d0a8b, 0x3e75c28f).toFloat // (0_187821, 0_187821, 0_215861, 0_24)
            case (.secondaryFill, .increased):
                (r, g, b, a) = _FourInt(0x3e405416, 0x3e405416, 0x3e5d0a8b, 0x3e75c28f).toFloat // (0_187821, 0_187821, 0_215861, 0_24)
            case (.tertiaryFill, .standard):
                (r, g, b, a) = _FourInt(0x3e405416, 0x3e405416, 0x3e5d0a8b, 0x3df5c28f).toFloat // (0_187821, 0_187821, 0_215861, 0_12)
            case (.tertiaryFill, .increased):
                (r, g, b, a) = _FourInt(0x3e39831e, 0x3e39831e, 0x3e5d0a8b, 0x3e4ccccc).toFloat // (0_181164, 0_181164, 0_215861, 0_2)
            case (.quaternaryFill, .standard):
                (r, g, b, a) = _FourInt(0x3e32d6c4, 0x3e32d6c4, 0x3e5d0a8b, 0x3da3d70a).toFloat // (0_174647, 0_174647, 0_215861, 0_08)
            case (.quaternaryFill, .increased):
                (r, g, b, a) = _FourInt(0x3e32d6c4, 0x3e32d6c4, 0x3e5d0a8b, 0x3df5c28f).toFloat // (0_174647, 0_174647, 0_215861, 0_12)
            }
        case .dark:
            switch (systemColorType, contrast) {
            case (.red, .standard):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3d73c20f, 0x3d2d4ebb, 0x3f800000).toFloat // (1, 0_0595112, 0_0423114, 1)
            case (.red, .increased):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3e10a752, 0x3df4d091, 0x3f800000).toFloat // (1, 0_141263, 0_119538, 1)
            case (.orange, .standard):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3eb18335, 0x3b46eb61, 0x3f800000).toFloat // (1, 0_346704, 0_00303527, 1)
            case (.orange, .increased):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3ee6cd67, 0x3d51ffef, 0x3f800000).toFloat // (1, 0_450786, 0_0512695, 1)
            case (.yellow, .standard):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3f2c253f, 0x3b46eb61, 0x3f800000).toFloat // (1, 0_672443, 0_00303527, 1)
            case (.yellow, .increased):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3f288b41, 0x3c9ec7c0, 0x3f800000).toFloat // (1, 0_658375 , _0_0193824, 1)
            case (.green, .standard):
                (r, g, b, a) = _FourInt(0x3cf2212c, 0x3f23398e, 0x3dc7dbe0, 0x3f800000).toFloat // (0_0295568, 0_637597, 0_0975873, 1)
            case (.green, .increased):
                (r, g, b, a) = _FourInt(0x3cf2212c, 0x3f355820, 0x3dd6412a, 0x3f800000).toFloat // (0_0295568, 0_708376, 0_104616, 1)
            case (.teal, .standard):
                (r, g, b, a) = _FourInt(0x3d51ffef, 0x3f13dc51, 0x3f3ed2d2, 0x3f800000).toFloat // (0_0512695, 0_577581 , 0_745404, 1)
            case (.teal, .increased):
                (r, g, b, a) = _FourInt(0x3de02d77, 0x3f4a9282, 0x3f800000, 0x3f800000).toFloat // (0_109462, 0_791298, 1, 1)
            case (.mint, _):
                (r, g, b, a) = _FourInt(0x3dff885e, 0x3f4a9282, 0x3f42b1be, 0x3f800000).toFloat // (0_124772, 0_791298, 0_760525, 1)
            case (.cyan, .standard):
                (r, g, b, a) = _FourInt(0x3e027f06, 0x3f24fca0, 0x3f800000, 0x3f800000).toFloat // (0_127438, 0_64448, 1, 1)
            case (.cyan, .increased):
                (r, g, b, a) = _FourInt(0x3e25eb07, 0x3f2df681, 0x3f800000, 0x3f800000).toFloat // (0_162029, 0_679543, 1, 1)
            case (.blue, .standard):
                (r, g, b, a) = _FourInt(0x3b46eb61, 0x3e6c4720, 0x3f800000, 0x3f800000).toFloat // (0_00303527, 0_23074, 1, 1)
            case (.blue, .increased):
                (r, g, b, a) = _FourInt(0x3d51ffef, 0x3eaa3718, 0x3f800000, 0x3f800000).toFloat // (0_0512695, 0_332452, 1, 1)
            case (.indigo, .standard):
                (r, g, b, a) = _FourInt(0x3de53cd5, 0x3ddb2eed, 0x3f4a9282, 0x3f800000).toFloat // (0_111932, 0_107023, 0_791298, 1)
            case (.indigo, .increased):
                (r, g, b, a) = _FourInt(0x3e52002b, 0x3e4749e8, 0x3f800000, 0x3f800000).toFloat // (0_205079, 0_194618, 1, 1)
            case (.purple, .standard):
                (r, g, b, a) = _FourInt(0x3f055ff9, 0x3dd1641c, 0x3f634ef1, 0x3f800000).toFloat // (0_520996, 0_102242, 0_887923, 1)
            case (.purple, .increased):
                (r, g, b, a) = _FourInt(0x3f337b6c, 0x3e8ca283, 0x3f800000, 0x3f800000).toFloat // (0_701102, 0_274677, 1, 1)
            case (.pink, .standard):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3d1c7c31, 0x3dea5d19, 0x3f800000).toFloat // (1, 0_0382044, 0_114435, 1)
            case (.pink, .increased):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3e027f06, 0x3e6495e0, 0x3f800000).toFloat // (1, 0_127438, 0_223228, 1)
            case (.brown, .standard):
                (r, g, b, a) = _FourInt(0x3ed338cc, 0x3e8a7eb2, 0x3e0dc104, 0x3f800000).toFloat // (0_412543, 0_270498, 0_138432, 1)
            case (.brown, .increased):
                (r, g, b, a) = _FourInt(0x3eec955d, 0x3e979f71, 0x3e10a752, 0x3f800000).toFloat // (0_462077, 0_296138, 0_141263, 1)
            case (.gray, .standard):
                (r, g, b, a) = _FourInt(0x3e8a7eb2, 0x3e8a7eb2, 0x3e9562f8, 0x3f800000).toFloat // (0_270498, 0_270498, 0_291771, 1)
            case (.gray, .increased):
                (r, g, b, a) = _FourInt(0x3ed8b68d, 0x3ed8b68d, 0x3ee3f16b, 0x3f800000).toFloat // (0_423268, 0_423268, 0_445201, 1)
            case (.primary, _):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000).toFloat // (1, 1, 1, 1)
            case (.secondary, .standard):
                (r, g, b, a) = _FourInt(0x3f54ad57, 0x3f54ad57, 0x3f69c0d8, 0x3f199999).toFloat // (0_83077, 0_83077, 0_913099, 0_6)
            case (.secondary, .increased):
                (r, g, b, a) = _FourInt(0x3f54ad57, 0x3f54ad57, 0x3f69c0d8, 0x3f333333).toFloat // (0_83077, 0_83077, 0_913099, 0_7)
            case (.tertiary, .standard):
                (r, g, b, a) = _FourInt(0x3f54ad57, 0x3f54ad57, 0x3f69c0d8, 0x3e999999).toFloat // (0_83077, 0_83077, 0_913099, 0_3)
            case (.tertiary, .increased):
                (r, g, b, a) = _FourInt(0x3f54ad57, 0x3f54ad57, 0x3f69c0d8, 0x3f0ccccd).toFloat // (0_83077, 0_83077, 0_913099, 0_55 )
            case (.quaternary, .standard):
                (r, g, b, a) = _FourInt(0x3f54ad57, 0x3f54ad57, 0x3f69c0d8, 0x3e23d70a).toFloat // (0_83077, 0_83077, 0_913099, 0_16 )
            case (.quaternary, .increased):
                (r, g, b, a) = _FourInt(0x3f54ad57, 0x3f54ad57, 0x3f69c0d8, 0x3ecccccc).toFloat // (0_83077, 0_83077, 0_913099, 0_4)
            case (.quinary, .standard):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3f800000, 0x3f800000, 0x3d4ccccd).toFloat // (1, 1, 1, 0_05)
            case (.quinary, .increased):
                (r, g, b, a) = _FourInt(0x3f800000, 0x3f800000, 0x3f800000, 0x3da6a6a7).toFloat // (1, 1, 1, 0_0813726)
            case (.primaryFill, .standard):
                (r, g, b, a) = _FourInt(0x3e405416, 0x3e405416, 0x3e5d0a8b, 0x3eb851eb).toFloat // (0_187821, 0_187821, 0_215861, 0_36)
            case (.primaryFill, .increased):
                (r, g, b, a) = _FourInt(0x3e405416, 0x3e405416, 0x3e5d0a8b, 0x3ee147ae).toFloat // (0_187821, 0_187821, 0_215861, 0_44)
            case (.secondaryFill, .standard):
                (r, g, b, a) = _FourInt(0x3e405416, 0x3e405416, 0x3e5d0a8b, 0x3ea3d70a).toFloat // (0_187821, 0_187821, 0_215861, 0_32)
            case (.secondaryFill, .increased):
                (r, g, b, a) = _FourInt(0x3e405416, 0x3e405416, 0x3e5d0a8b, 0x3ecccccc).toFloat // (0_187821, 0_187821, 0_215861, 0_4)
            case (.tertiaryFill, .standard):
                (r, g, b, a) = _FourInt(0x3e39831e, 0x3e39831e, 0x3e5d0a8b, 0x3e75c28f).toFloat // (0_181164, 0_181164, 0_215861, 0_24)
            case (.tertiaryFill, .increased):
                (r, g, b, a) = _FourInt(0x3e39831e, 0x3e39831e, 0x3e5d0a8b, 0x3ea3d70a).toFloat // (0_181164, 0_181164, 0_215861, 0_32)
            case (.quaternaryFill, .standard):
                (r, g, b, a) = _FourInt(0x3e32d6c4, 0x3e32d6c4, 0x3e5d0a8b, 0x3e3851eb).toFloat // (0_174647, 0_174647, 0_215861, 0_18)
            case (.quaternaryFill, .increased):
                (r, g, b, a) = _FourInt(0x3e32d6c4, 0x3e32d6c4, 0x3e5d0a8b, 0x3e851eb8).toFloat // (0_174647, 0_174647, 0_215861, 0_26)
            }
        
        }
        return .init(linearRed: r, linearGreen: g, linearBlue: b, opacity: a)
    }
}

@available(iOS 13.0, *)
fileprivate struct SystemColorDefinitionKey: EnvironmentKey {
    
    internal typealias Value = SystemColorDefinition.Type
    
    internal static var defaultValue: Value {
        DefaultSystemColorDefinition.self
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    fileprivate var systemColorDefinition: SystemColorDefinition.Type {
        self[SystemColorDefinitionKey.self]
    }
    
    @inline(__always)
    internal func colorOpacity(with levels: Int) -> Float {
        systemColorDefinition.opacity(at: levels, environment: self)
    }
}

@available(iOS 13.0, *)
fileprivate func _UIColorDependsOnTraitCollection(_ color: UIColor) -> Bool {
    if #available(iOS 13, *) {
        struct Store {
            static let selector = #selector(UIColor.resolvedColor(with:))
            
            static let UIColor_imp = {
                UIColor.instanceMethod(for: Store.selector)
            }()
        }
        return Store.UIColor_imp != color.method(for: Store.selector)
    }
    return false
}

@available(iOS 13.0, *)
extension UIColor: _ColorProvider {
    
    @_spi(DanceUICompose)
    public func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        if #available(iOS 13.0, *), _UIColorDependsOnTraitCollection(self) {
            return autoreleasepool {
                let overridenTraitCollection = UITraitCollection.current.byOverriding(with: environment)
                let resolvedUIColor = resolvedColor(with: overridenTraitCollection)
                return Color.Resolved(resolvedUIColor)!
            }
        }
        return Color.Resolved(failableCGColor: self.cgColor)!
    }
    
    internal var staticColor: CGColor? {
        guard _UIColorDependsOnTraitCollection(self) else {
            return self.cgColor
        }
        return nil
    }
}

@available(iOS 13.0, *)
extension CGColor: _ColorProvider {
    
    internal func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        Color.Resolved(failableCGColor: self) ?? .empty
    }
    
    internal var staticColor: CGColor? {
        self
    }
}

@available(iOS 13.0, *)
internal final class ObjCColor: NSObject {
    
    internal let color: Color
    
    internal init(color: Color) {
        self.color = color
    }
    
    internal override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? ObjCColor else {
            return false
        }
        return object.color == color
    }
    
    internal override var hash: Int {
        color.hashValue
    }
}

@available(iOS 13.0, *)
internal let dynamicColorCache: NSMapTable<ObjCColor, UIColor> = .strongToWeakObjects()
@available(iOS 13.0, *)
extension UIColor {
    
    public convenience init(_ color: Color) {
        if let staticColor = color._box.staticColor {
            self.init(cgColor: staticColor)
            return
        }
        let key = ObjCColor(color: color)
        if let result = dynamicColorCache.object(forKey: key) {
            self.init(color__My: result)
            return
        }
        if #available(iOS 13, *) {
            self.init { traitCollection in
                color.resolvedUIColor(in: traitCollection.baseEnvironment)
            }
        } else {
            self.init(color__My: color.resolvedUIColor(in: EnvironmentValues()))
        }
        dynamicColorCache.setObject(self, forKey: key)
        return
    }
}

@usableFromInline
@available(iOS 13.0, *)
internal func sRGBToLinear(_ sRGB: Float) -> Float {
    let guardedSRGB = 0 < sRGB ? sRGB : -sRGB
    
    let result: Float
    
    if guardedSRGB <= 0.04045 {
        result = guardedSRGB * Float(bitPattern: 0x3d9e8391)
    } else {
        result = pow(((guardedSRGB * Float(bitPattern: 0x3f72a76f)) + Float(bitPattern: 0x3d55891a)), 2.4)
    }
    return Float(0 < sRGB ? result : -result)
}

@usableFromInline
@available(iOS 13.0, *)
internal func linearToSRGB(_ linear: Float) -> Float {
    let guardedLinear = 0 < linear ? linear : -linear
    
    let result: Float
    
    if guardedLinear <= Float(bitPattern: 0x3b4d2e1c) {
        result = guardedLinear * Float(bitPattern: 0x414eb852)
    } else {
        result = pow(guardedLinear, Float(bitPattern: 0x3ed55555)) * Float(bitPattern: 0x3f870a3d) + Float(bitPattern: 0xbd6147ae)
    }
    
    return 0 < linear ? result : -result
}

@usableFromInline
@available(iOS 13.0, *)
internal func HSBToRGB(hue: Double, saturation: Double, brightness: Double) -> (red: Double, green: Double, blue: Double) {
    
    let h_60: Double = (hue == 1.0) ? 0.0 : 6.0 * hue
    let hi = Int(h_60)
    let f = h_60 - Double(hi)
    
    let p = (1.0 - saturation) * brightness
    let q = (1.0 - saturation * f) * brightness
    let t = (1.0 - saturation * (1.0 - f)) * brightness
    
    var r = 0.0, g = 0.0, b = 0.0
    switch(hi) {
    case 0:
        r = brightness
        g = t
        b = p
    case 1:
        r = q
        g = brightness
        b = p
    case 2:
        r = p
        g = brightness
        b = t
    case 3:
        r = p
        g = q
        b = brightness
    case 4:
        r = t
        g = p
        b = brightness
    default:
        r = brightness
        g = p
        b = q
    }
    
    return (r, g, b)
}

@available(iOS 13.0, *)
extension Int {
    
    internal var toFloat: Float {
        .init(bitPattern: UInt32(self))
    }
}

@available(iOS 13.0, *)
fileprivate struct _FourInt {
    
    fileprivate let r, g, b, a: Int
    
    @inline(__always)
    fileprivate init(_ r: Int, _ g: Int, _ b: Int, _ a: Int) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }
    
    @inline(__always)
    fileprivate var toFloat: (Float, Float, Float, Float) {
        (r.toFloat, g.toFloat, b.toFloat, a.toFloat)
    }
}

@available(iOS 13.0, *)
extension Color: Equatable {

    /// Indicates whether two colors are equal.
    ///
    /// - Parameters:
    ///   - lhs: The first color to compare.
    ///   - rhs: The second color to compare.
    /// - Returns: A Boolean that's set to `true` if the two colors are equal.
    public static func == (lhs: Color, rhs: Color) -> Bool {
        lhs._box.isEqual(to: rhs._box)
    }
}

@available(iOS 13.0, *)
extension Color {

    /// Creates a color from a Core Graphics color.
    ///
    /// - Parameter color: CGColor
    public init(_ cgColor: CGColor) {
        self.init(provider: cgColor)
    }
    
    public init(cgColor: CGColor) {
        self.init(provider: cgColor)
    }
    
    /// A Core Graphics representation of the color, if available.
    ///
    /// For a dynamic color, like one you load from an Asset Catalog using
    /// ``init(_:bundle:)``, or one you create from a dynamic UIKit or AppKit
    /// color, this property is `nil`.
    public var cgColor: CGColor? {
        self._box.staticColor
    }
}
