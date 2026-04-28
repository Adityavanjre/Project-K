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
internal protocol BodyAccessor {

    associatedtype Container

    associatedtype Body

    func updateBody(of container: Container, changed: Bool)
}

@available(iOS 13.0, *)
internal protocol BodyAccessorRule {

    static var container: Any.Type { get }

    static func value<A>(as: A.Type, attribute: DGAttribute) -> A?

    static func buffer<A>(as: A.Type, attribute: DGAttribute) -> _DynamicPropertyBuffer?

    static func metaProperties<A>(as: A.Type, attribute: DGAttribute) -> [(String, DGAttribute)]

}

@available(iOS 13.0, *)
extension BodyAccessor {

    @inlinable
    internal func makeBody(container: _GraphValue<Container>, inputs: inout _GraphInputs, fields: DynamicPropertyCache.Fields) -> (_GraphValue<Body>, _DynamicPropertyBuffer?) {
        _danceuiPrecondition(Body.self != Never.self, "views must be value types: \(_typeName(Body.self, qualified: false))")

        guard !fields.layout.isEmpty else {
            @Attribute(StaticBody(accessor: self, container: container.value))
            var body: Body
            $body.flags = .removable
#if DEBUG || DANCE_UI_INHOUSE
            $body.role = .body
            $body.association = .bodyAccessor(containerType: Container.self)
#endif
            return (_GraphValue($body), nil)
        }
        let links = _DynamicPropertyBuffer(fields: fields,
                                           container: container,
                                           inputs: &inputs)
        @Attribute(DynamicBody(accessor: self,
                               container: container.value,
                               phase: inputs.phase,
                               links: links,
                               resetSeed: 0))
        var body: Body
        $body.flags = .removable
#if DEBUG || DANCE_UI_INHOUSE
        $body.role = .body
        $body.association = .bodyAccessor(containerType: Container.self)
#endif
        return (_GraphValue($body), links)
    }

    @inlinable
    internal func setBody(body: () -> Body) {
        let value = traceRuleBody(Container.self) { () -> Body in
            return DGGraphRef.withoutUpdate(body)
        }

        withUnsafePointer(to: value) { (ptr) in
            DGGraphSetOutputValue(ptr)
        }
    }

}
