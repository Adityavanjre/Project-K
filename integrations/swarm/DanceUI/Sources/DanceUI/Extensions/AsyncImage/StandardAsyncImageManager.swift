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
public final class StandardAsyncImageManager: AsyncImageManager {
    
    public static let shared = StandardAsyncImageManager()
    
    // MARK: - Memory Cache
    
    private let memoryCache: NSCache<NSString, UIImage>
    
    // MARK: - Initialization
    
    private init() {
        memoryCache = NSCache<NSString, UIImage>()
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - AsyncImageManager Protocol
    
    public func prefetch(_ urls: [URL], cache: AsyncImageCache) {
    }
    
    public func clearMemoryCache(_ cache: AsyncImageCache) -> Self {
        memoryCache.removeAllObjects()
        return self
    }
    
    public func clearDiskCache(_ cache: AsyncImageCache) -> Self {
        return self
    }
    
    public func registerCache(_ key: String, settings: AsyncImageCacheSettings) -> Self {
        return self
    }
    
    public func setupCacheKeyCreater(_ creater: @escaping (URL?) -> String?) -> Self {
        return self
    }
    
    public func enableLog(_ enable: Bool) -> Self {
        return self
    }
    
    public func memoryImage(for url: String, options: Set<AsyncImageOption>, cache: AsyncImageCache) -> UIImage? {
        return memoryCache.object(forKey: url as NSString)
    }
    
    public func diskImage(for url: String, options: Set<AsyncImageOption>, cache: AsyncImageCache) -> UIImage? {
        return nil
    }
    
    public func setupManager(_ type: AsyncImageManagerType) -> Self {
        return self
    }
    
    // MARK: - Internal Methods
    
    internal func memoryImage(for key: String) -> UIImage? {
        return memoryCache.object(forKey: key as NSString)
    }
    
    internal func setMemoryImage(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    // MARK: - Private Methods
    
    @objc private func handleMemoryWarning() {
        memoryCache.removeAllObjects()
    }
}
