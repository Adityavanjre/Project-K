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

internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct LayoutComputer: Equatable, Defaultable {

    internal typealias Value = LayoutComputer

    internal var seed: Int

    internal var engine: AnyLayoutEngineBox
    
    @inlinable
    internal init() {
        self.seed = 0
        self.engine = LayoutEngineBox(engine: DefaultEngine())
    }
    
    @inlinable
    internal init<Engine: LayoutEngine>(seed: Int, engine: Engine) {
        self.seed = seed
        self.engine = LayoutEngineBox(engine: engine)
    }
    
    @inlinable
    internal init(seed: Int, engineBox: AnyLayoutEngineBox) {
        self.seed = seed
        self.engine = engineBox
    }
    
    internal static func == (lhs: LayoutComputer, rhs: LayoutComputer) -> Bool {
        lhs.seed == rhs.seed && lhs.engine === rhs.engine
    }
    
    internal static var defaultValue: LayoutComputer {
        LayoutComputer()
    }
}


@available(iOS 13.0, *)
extension LayoutComputer {
    
    internal struct DefaultEngine: LayoutEngine {
        
        internal var debugDescription: String {
            "\(Self.self)"
        }
        
        internal func lengthThatFits(_ proposedSize: _ProposedSize, in axis: Axis) -> CGFloat {
            let size = sizeThatFits(proposedSize)
            return axis == .horizontal ? size.width : size.height
        }
        
        internal func spacing() -> Spacing {
            .zeroText
        }
        
        internal func requiresSpacingProjection() -> Bool {
            false
        }
        
        internal func sizeThatFits(_ size: _ProposedSize) -> CGSize {
            let width = size.width ?? 0xa
            let height = size.height ?? 0xa
            return CGSize(width: width, height: height)
        }
        
        @inlinable
        internal func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
            nil
        }
        
        @inlinable
        internal func layoutPriority() -> Double {
            0
        }
    }
    
}

@available(iOS 13.0, *)
extension StatefulRule where Value == LayoutComputer {
    
    internal mutating func updateLayoutComputer<Layout: _Layout>(layout: Layout,
                                                                 environment: Attribute<EnvironmentValues>,
                                                                 layoutAttributes: [LayoutProxyAttributes]) {
        let context = SizeAndSpacingContext(environment: environment)
        let children = LayoutProxyCollection(context: context.context, attributes: layoutAttributes)
        layout.updateLayoutComputer(rule: &self, layoutContext: context, children: children)
    }
    
}
