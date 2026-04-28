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
extension EnvironmentValues {

    /// Whether the system preference for Differentiate without Color is enabled.
    ///
    /// If this is true, UI should not convey information using color alone
    /// and instead should use shapes or glyphs to convey information.
    public var accessibilityDifferentiateWithoutColor: Bool {
        self[AccessibilityDifferentiateWithoutColorKey.self]
    }
    
    public var _accessibilityDifferentiateWithoutColor: Bool {
        get {
            self[AccessibilityDifferentiateWithoutColorKey.self]
        }
        set {
            self[AccessibilityDifferentiateWithoutColorKey.self] = newValue
        }
    }

    /// Whether the system preference for Reduce Transparency is enabled.
    ///
    /// If this property's value is true, UI (mainly window) backgrounds should
    /// not be semi-transparent; they should be opaque.
    public var accessibilityReduceTransparency: Bool {
        self[AccessibilityReduceTransparencyKey.self]
    }
    
    public var _accessibilityReduceTransparency: Bool {
        get {
            self[AccessibilityReduceTransparencyKey.self]
        }
        set {
            self[AccessibilityReduceTransparencyKey.self] = newValue
        }
    }

    /// Whether the system preference for Reduce Motion is enabled.
    ///
    /// If this property's value is true, UI should avoid large animations,
    /// especially those that simulate the third dimension.
    public var accessibilityReduceMotion: Bool {
        self[AccessibilityReduceMotionKey.self]
    }
    
    public var _accessibilityReduceMotion: Bool {
        get {
            self[AccessibilityReduceMotionKey.self]
        }
        set {
            self[AccessibilityReduceMotionKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {

    /// Whether the system preference for Show Button Shapes is enabled.
    ///
    /// If this property's value is true, interactive custom controls
    /// such as buttons should be drawn in such a way that their edges
    /// and borders are clearly visible.
    public var accessibilityShowButtonShapes: Bool {
        self[AccessibilityButtonShapesKey.self]
    }
    
    public var _accessibilityShowButtonShapes: Bool {
        get {
            self[AccessibilityButtonShapesKey.self]
        }
        set {
            self[AccessibilityButtonShapesKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct AccessibilityDifferentiateWithoutColorKey: EnvironmentKey {
    
    fileprivate typealias Value = Bool
    
    @inline(__always)
    fileprivate static var defaultValue: Value { false }
    
}

@available(iOS 13.0, *)
fileprivate struct AccessibilityReduceTransparencyKey: EnvironmentKey {
    
    fileprivate typealias Value = Bool
    
    @inline(__always)
    fileprivate static var defaultValue: Value { false }
    
}

@available(iOS 13.0, *)
fileprivate struct AccessibilityReduceMotionKey: EnvironmentKey {
    
    fileprivate typealias Value = Bool
    
    @inline(__always)
    fileprivate static var defaultValue: Value { false }
    
}

@available(iOS 13.0, *)
fileprivate struct AccessibilityButtonShapesKey: EnvironmentKey {
    
    @inline(__always)
    fileprivate static var defaultValue: Bool { false }
    
}
