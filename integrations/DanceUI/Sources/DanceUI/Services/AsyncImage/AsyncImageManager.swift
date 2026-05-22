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
public struct AsyncImageCacheSettings : Hashable {

    /// Maximum memory cache object count limit, default unlimited
    public var memoryCountLimit: UInt
    /// Maximum memory cache size in bytes, default 100 MB
    public var memorySizeLimit: UInt

    /// Maximum disk cache object count limit, default unlimited
    public var diskCountLimit: UInt
    /// Maximum disk cache size in bytes, default 256MB
    public var diskSizeLimit: UInt
    /// Maximum disk cache expiration time in seconds, default 7 days
    public var diskAgeLimit: UInt
    
    public init(memoryCountLimit: UInt = .max,
                memorySizeLimit: UInt = 100 * 1024 * 1024,
                diskCountLimit: UInt = .max,
                diskSizeLimit: UInt = 256 * 1024 * 1024,
                diskAgeLimit: UInt = 7 * 24 * 60 * 60) {
        self.memoryCountLimit = memoryCountLimit
        self.memorySizeLimit = memorySizeLimit
        self.diskCountLimit = diskCountLimit
        self.diskSizeLimit = diskSizeLimit
        self.diskAgeLimit = diskAgeLimit
    }
}

@frozen
@available(iOS 13.0, *)
public enum AsyncImageCache {
    case shared
    case custom(String)
}

@frozen
@available(iOS 13.0, *)
public enum AsyncImageManagerType: Equatable {
    case shared
    case category(String?)
}

@available(iOS 13.0, *)
public protocol AsyncImageManager {
    func prefetch(_ urls: [URL], cache: AsyncImageCache)
    func clearMemoryCache(_ cache: AsyncImageCache) -> Self
    func clearDiskCache(_ cache: AsyncImageCache) -> Self
    func registerCache(_ key: String, settings: AsyncImageCacheSettings) -> Self
    func setupCacheKeyCreater(_ creater: @escaping (URL?) -> String?) -> Self
    func enableLog(_ enable: Bool) -> Self
    func memoryImage(for url: String, options: Set<AsyncImageOption>, cache: AsyncImageCache) -> UIImage?
    func diskImage(for url: String, options: Set<AsyncImageOption>, cache: AsyncImageCache) -> UIImage?
    func setupManager(_ type: AsyncImageManagerType) -> Self
}

@available(iOS 13.0, *)
extension AsyncImageManager {
    

    public func memoryImage(for url: String, options: Set<AsyncImageOption> = []) -> UIImage? {
        memoryImage(for: url, options: options, cache: .shared)
    }
    

    public func diskImage(for url: String, options: Set<AsyncImageOption> = []) -> UIImage? {
        diskImage(for: url, options: options, cache: .shared)
    }


    public func memoryImage(for url: String, options: Set<AsyncImageOption>, cache: AsyncImageCache) -> UIImage? {
        nil
    }


    public func diskImage(for url: String, options: Set<AsyncImageOption>, cache: AsyncImageCache) -> UIImage? {
        nil
    }
    

    public func setupManager(_ type: AsyncImageManagerType) -> Self {
        return self
    }
}
