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
public struct PopoverPresentation {

    internal var content: AnyView

    internal var arrowEdge: ArrowEdge?

    internal var targetAnchor: Anchor<CGRect?>

    internal var onDismiss: () -> ()

    internal var isDetachable: Bool

    internal var viewID: ViewIdentity

    internal var itemID: AnyHashable?

    internal var environment: EnvironmentValues
    
    public var adaptivePresentationStyle: Bool = true
    
    public var hasArrowBackgroundView: Bool = true
    
    public var canOverlapSourceViewRect: Bool = false
    
    public var layoutMargins: EdgeInsets? = nil
    
    public var backgroundViewClass: UIPopoverBackgroundViewMethods.Type? = nil
    
    internal var dismissedProgramatically: Bool = false
    
    public struct ArrowEdge: OptionSet {
                
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let top: ArrowEdge = .init(rawValue: 0x1 << 0)
        public static let leading: ArrowEdge = .init(rawValue: 0x1 << 1)
        public static let bottom: ArrowEdge = .init(rawValue: 0x1 << 2)
        public static let trailing: ArrowEdge = .init(rawValue: 0x1 << 3)
    }


    public struct Key : HostPreferenceKey {

        public typealias Value = [PopoverPresentation]
        
        @inline(__always)
        public static var defaultValue: [PopoverPresentation] { [] }
        
        public static func reduce(value: inout [PopoverPresentation], nextValue: () -> [PopoverPresentation]) {
            value.append(contentsOf: nextValue())
        }
    }

}

@available(iOS 13.0, *)
extension PopoverPresentation.ArrowEdge {
    
    internal var arrowDirection: UIPopoverArrowDirection {
        var arrowDirection = UIPopoverArrowDirection()
        if contains(.top) {
            arrowDirection.insert(.down)
        }
        if contains(.leading) {
            arrowDirection.insert(.right)
        }
        if contains(.bottom) {
            arrowDirection.insert(.up)
        }
        if contains(.trailing) {
            arrowDirection.insert(.left)
        }
        return arrowDirection
    }
    
    internal var edges: [Edge] {
        var edge = [Edge]()
        if contains(.top) {
            edge.append(.top)
        }
        if contains(.leading) {
            edge.append(.leading)
        }
        if contains(.bottom) {
            edge.append(.bottom)
        }
        if contains(.trailing) {
            edge.append(.trailing)
        }
        return edge
    }
    
    internal init(_ edge: Edge) {
        switch edge {
        case .top:
            self = .top
        case .leading:
            self = .leading
        case .bottom:
            self = .bottom
        case .trailing:
            self = .trailing
        }
    }
}

@available(iOS 13.0, *)
internal final class PopoverWithoutArrowBackgroundView: UIPopoverBackgroundView {
    
    internal override static func contentViewInsets() -> UIEdgeInsets {
        return .zero
    }
    
    internal override static func arrowHeight() -> CGFloat {
        return 0
    }
    
    internal override var arrowDirection: UIPopoverArrowDirection {
        get { return .unknown }
        set { }
    }
    
    internal override var arrowOffset: CGFloat {
        get { return 0 }
        set { }
    }
    
    internal override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.shadowOpacity = 0
    }
}
