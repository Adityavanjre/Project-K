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

internal import Resolver

internal import DanceUIGraph

@available(iOS 13.0, *)
internal final class AsyncImageResover {
    
#if DEBUG
    internal static var resetEnable: Bool = false
#endif
    
    internal static var _resolved: AsyncImageInner.Type?
    
    internal static var resolved: AsyncImageInner.Type? {
#if DEBUG
        if !resetEnable, let _resolved = _resolved {
            return _resolved
        }
#else
        if let _resolved = _resolved {
            return _resolved
        }
#endif
        if let inner = Resolver.services.optional(AsyncImageInner.self) {
            LogService.info(module: .image, keyword: .resolveInner, "AsyncImage resolve inner success", info: ["inner": inner])
            _resolved = type(of: inner)
            return _resolved
        }
        // AsyncImage backend parsing exception case handling
        LogService.error(module: .image, keyword: .resolveInner, "AsyncImage resolve inner fail")
        return nil
    }
}

@available(iOS 13.0, *)
extension AsyncImage {
    
    public static func _makeView(view: _GraphValue<AsyncImage<Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        guard let innerType = AsyncImageResover.resolved else {
            assertionFailure("AsyncImage can't resolve the extension Impl")
            return _ViewOutputs()
        }
        return innerType._makeView(view: view, inputs: inputs)
    }
    
    public static func _makeViewList(view: _GraphValue<AsyncImage<Content>>, inputs: _ViewListInputs) -> _ViewListOutputs {
        guard let innerType = AsyncImageResover.resolved else {
            return .unaryViewList(view: view, inputs: inputs)
        }
        return innerType._makeViewList(view: view, inputs: inputs)
    }
    
}

@available(iOS 13.0, *)
public protocol AsyncImageInner {
    
    static func _makeView<Content>(view: _GraphValue<AsyncImage<Content>>, inputs: _ViewInputs) -> _ViewOutputs
    static func _makeViewList<Content>(view: _GraphValue<AsyncImage<Content>>, inputs: _ViewListInputs) -> _ViewListOutputs
}

