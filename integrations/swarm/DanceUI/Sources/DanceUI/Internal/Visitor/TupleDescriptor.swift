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
internal protocol TupleDescriptor: ProtocolDescriptor {

    static var typeCache: [ObjectIdentifier: TupleTypeDescription<Self>] { get set }

    static var asyncTypeCache: AsyncCache<[ObjectIdentifier: TupleTypeDescription<Self>]> { get set }
}

@available(iOS 13.0, *)
extension TupleDescriptor {

    internal static func typeDescription(_ tupleType: DGTupleType) -> TupleTypeDescription<Self> {
        let key = ObjectIdentifier(tupleType.type)
        return Self.withCache { cache in
            if let value = cache[key] {
                return value
            } else {
                let tupleTypeDesc = TupleTypeDescription<Self>(tupleType)
                cache[key] = tupleTypeDesc
                return tupleTypeDesc
            }
        }
    }

    @inline(__always)
    internal static func withCache<R>(_ body: (inout [ObjectIdentifier : TupleTypeDescription<Self>]) -> R) -> R {
        guard DanceUIFeature.hostingConfigurationReaderAsyncComputerSize.isEnable else {
            return body(&typeCache)
        }
        if Thread.isMainThread {
            return body(&typeCache)
        } else {
            return asyncTypeCache.withMutableContent { cache in
                body(&cache)
            }
        }
    }
}
