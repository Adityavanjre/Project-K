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
extension Color.Resolved {
    
    fileprivate static let cgCache: ObjectCache<Color.Resolved, CGColor> = .init {
        CGColor(colorSpace: Color.Resolved.colorSpace,
                components: [CGFloat($0.red), CGFloat($0.green),
                             CGFloat($0.blue), CGFloat($0.alpha)])!
    }
    
    @inline(__always)
    internal var cgColor: CGColor {
        Color.Resolved.cgCache[self]
    }
}

@available(iOS 13.0, *)
extension Color.Resolved {
    
    fileprivate static let uiCache: ObjectCache<Color.Resolved, UIColor> = .init {
        UIColor(
            red: CGFloat($0.red),
            green: CGFloat($0.green),
            blue: CGFloat($0.blue),
            alpha: CGFloat($0.alpha)
        )
    }
    
    fileprivate static let asyncUICache: AsyncCache<ObjectCache<Color.Resolved, UIColor>> = .init(ObjectCache {
        UIColor(
            red: CGFloat($0.red),
            green: CGFloat($0.green),
            blue: CGFloat($0.blue),
            alpha: CGFloat($0.alpha)
        )
    })
    
    @inline(__always)
    internal var uiColor: UIColor {
        Color.Resolved.withCache { cache in
            cache[self]
        }
    }
    
    @inline(__always)
    internal static func withCache<R>(_ body: (ObjectCache<Color.Resolved, UIColor>) -> R) -> R {
        guard DanceUIFeature.hostingConfigurationReaderAsyncComputerSize.isEnable else {
            return body(uiCache)
        }
        if Thread.isMainThread {
            return body(uiCache)
        } else {
            return asyncUICache.withContent { cache in
                body(cache)
            }
        }
    }
}

@available(iOS 13.0, *)
extension Color {
    
    @inline(__always)
    internal func resolvedUIColor(in environment: EnvironmentValues) -> UIColor {
        
        let resolveColor = self.resolvePaint(in: environment)
        
        return resolveColor.uiColor
    }
    
    @inline(__always)
    internal func resolvedCGColor(in environment: EnvironmentValues) -> CGColor {
        
        let resolveColor = self.resolvePaint(in: environment)
        
        return resolveColor.cgColor
    }
}
