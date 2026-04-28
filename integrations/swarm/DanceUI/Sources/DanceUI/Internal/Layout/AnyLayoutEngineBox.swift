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
internal class AnyLayoutEngineBox {
    
    func layoutPriority() -> Double {
        _abstractFunction()
    }
    
    func ignoresAutomaticPadding() -> Bool {
        _abstractFunction()
    }
    
    func spacing() -> Spacing {
        _abstractFunction()
    }
    
    func requiresSpacingProjection() -> Bool {
        _abstractFunction()
    }
    
    func sizeThatFits(_ size: _ProposedSize) -> CGSize {
        _abstractFunction()
    }
    
    func lengthThatFits(_ proposedSize: _ProposedSize, in axis: Axis) -> CGFloat {
        _abstractFunction()
    }
    
    func childGeometries(at: ViewSize, origin: CGPoint) -> [ViewGeometry] {
        _abstractFunction()
    }
    
    func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
        _abstractFunction()
    }

}

@available(iOS 13.0, *)
internal final class LayoutEngineBox<Engine: LayoutEngine>: AnyLayoutEngineBox {
    
    var engine : Engine
    
    internal init(engine: Engine) {
        self.engine = engine
    }
    
    override func layoutPriority() -> Double {
        engine.layoutPriority()
    }
    
    override func ignoresAutomaticPadding() -> Bool {
        engine.ignoresAutomaticPadding()
    }
    
    override func spacing() -> Spacing {
        engine.spacing()
    }
    
    override func requiresSpacingProjection() -> Bool {
        engine.requiresSpacingProjection()
    }
    
    override func sizeThatFits(_ size: _ProposedSize) -> CGSize {
        engine.sizeThatFits(size)
    }
    
    override func childGeometries(at size: ViewSize, origin: CGPoint) -> [ViewGeometry] {
        engine.childGeometries(at: size, origin: origin)
    }
    
    override func lengthThatFits(_ proposedSize: _ProposedSize, in axis: Axis) -> CGFloat {
        engine.lengthThatFits(proposedSize, in: axis)
    }
    
    override func explicitAlignment(_ key: AlignmentKey,
                                    at size: ViewSize) -> CGFloat? {
        engine.explicitAlignment(key, at: size)
    }
    
    internal static func update<Rule: StatefulRule>(_ rule: inout Rule,
                                                    inPlace: (LayoutEngineBox<Engine>) -> (),
                                                    create: () -> LayoutEngineBox<Engine>) where Rule.Value == LayoutComputer {
        update(&rule, maybeInPlace: { delegate in
            inPlace(delegate)
            return true
        }, create: create)
    }
    
    internal static func update<Rule: StatefulRule>(_ rule: inout Rule,
                                                    maybeInPlace: (LayoutEngineBox<Engine>) -> Bool,
                                                    create: () -> LayoutEngineBox<Engine>) where Rule.Value == LayoutComputer {
        guard rule.hasValue else {
            rule.value = LayoutComputer(seed: 0, engineBox: create())
            return
        }
        var layoutComputer = rule.value
        layoutComputer.seed &+= 1
        if let engine = layoutComputer.engine as? Self, maybeInPlace(engine) {
            rule.value = layoutComputer
        } else {
            layoutComputer.engine = LayoutEngineBox(engine: LayoutComputer.DefaultEngine() as! Engine)
            rule.value = layoutComputer
            var newLayoutComputer: LayoutComputer = rule.value
            newLayoutComputer.engine = create()
            rule.value = newLayoutComputer
        }
    }
    
}
