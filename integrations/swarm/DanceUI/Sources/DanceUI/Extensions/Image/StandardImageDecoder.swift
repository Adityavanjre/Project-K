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
internal import Resolver

/// 标准的图片解码器，基于 NSCache 和 UIImage 初始化实现
/// 不提供实际的预解码能力，仅作为接口的标准实现
@available(iOS 13.0, *)
public struct StandardImageDecoder: ImageDecoder, ServiceRegister {
    
    // MARK: - Cache
    
    private static let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 50
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        return cache
    }()
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - ImageDecoder Protocol
    
    public func decodeForDisplay(_ cgImage: CGImage, key: String) -> CGImage? {
        // 不做实际解码，直接返回原图
        return cgImage
    }
    
    public func decodedImage(for key: String) -> CGImage? {
        return Self.imageCache.object(forKey: key as NSString)?.cgImage
    }
    
    public func decodedImage(with data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    public func decodedImage(with path: String) -> UIImage? {
        // 检查缓存
        if let cached = Self.imageCache.object(forKey: path as NSString) {
            return cached
        }
        
        // 使用 UIImage 初始化
        guard let image = UIImage(contentsOfFile: path) else {
            return nil
        }
        
        // 缓存
        Self.imageCache.setObject(image, forKey: path as NSString)
        return image
    }
    
    // MARK: - ServiceRegister
    
    @_silgen_name("DanceUIExtension.AsyncImage.StandardImageDecoder")
    public static func register() {
        Resolver.services.register {
            StandardImageDecoder() as ImageDecoder
        }.scope(.shared)
    }
    
    // MARK: - Cache Management
    
    /// 清除缓存
    public static func clearCache() {
        imageCache.removeAllObjects()
    }
}
