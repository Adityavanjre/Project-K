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
import CoreGraphics

@available(iOS 13.0, *)
public enum AsyncImageOption : Hashable {
    
    /// If in waiting queue, tasks sorted by priority, downloading task priority corresponds to operationPriority
    case defaultPriority
    case lowPriority
    case highPriority
    case notRetry
    /// Custom download timeout interval, timeout reports timeout error
    case timeoutInterval(CFTimeInterval)
    
    /// Specify custom cache, need to register cache with corresponding cacheName first
    /// Images loaded by DanceUI are cached in DanceUIAsyncImageCache by default
    case cacheName(String)
    /// Whether to ignore memory cache, default uses, prioritizes memory cache lookup
    case ignoreMemoryCache
    /// Whether to ignore disk cache, default uses
    case ignoreDiskCache
    /// Whether to ignore network image request, default requests network image
    case ignoreNetworkImage
    /// Whether to ignore caching to memory after download, default caches
    case notCacheToMemery
    /// Whether to ignore caching to disk after download, default caches
    case notCacheToDisk
    
    /// Specify downsample size, image size after loading, default zero shows original size
    /// After image download, will downsample according to downsampleSize during decoding
    case imageDownsample(CGSize)

    /// Image uses smart crop, requires server support, returns smart crop area in header
    case imageSmartCorp
    /// Disable image pre-decoding.
    case imageDisableBackgroundDecode
    /// Enable progressive download for animated images
    case imageProgressiveDownload
    /// Image transformation
    case imageProcessor(AsyncImageProcessor)
    
    /// Custom info carried during image loading for tracking, received in ``View/onImageLoad(_:)`` callback
    case customInfo([String:AnyHashable])
    
    /// Request configuration for image loading
    case config(_AsyncImageConfig)
    
    // Reserved extension field for image loading backend request config, Int value is actual backend request option rawValue
    case _optionValue(_Value)
    
    public struct _Value: Hashable {
        
        @_spi(DanceUIExtension)
        @_spi(DanceUICompose)
        public var rawValue: Int
        
        @_spi(DanceUIExtension)
        @_spi(DanceUICompose)
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

@available(iOS 13.0, *)
public struct _AsyncImageConfig : Hashable {
    
    /// In image library report logs, some include scene_tag as app scene identifier, priority as follows
    /// 1. Setting sceneTag in config for each image request has highest priority
    /// 2. If BDWebImageManager sceneTagURLFilterBlock is set, it will use current URL as parameter to generate scene_tag
    public let sceneTag: String
    
    /// Currently @b bizTag is used in various BDWebImage report logs
    /// Used to distinguish business scenarios
    /// In image library report logs, biz_tag priority is as follows
    ///      1. Set using current BDImageRequest biz_tag property (Warning: do not use this, prefer methods below)
    ///      2. Set via global query @p bizTagURLFilterBlock
    ///      3. If current URL has from parameter, parse from it to fill bizTag
    public let bizTag: String
    
    public init(sceneTag: String = "", bizTag: String = "") {
        self.sceneTag = sceneTag
        self.bizTag = bizTag
    }
}

@available(iOS 13.0, *)
public struct AsyncImageProcessor : Hashable {
    public var processorKey: String
    public var processImage: (UIImage) -> UIImage
    
    public init(_ processorKey: String, _ processImage: @escaping (UIImage) -> UIImage = { $0 }) {
        self.processorKey = processorKey
        self.processImage = processImage
    }
    
    public var hashValue: Int {
        processorKey.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        processorKey.hash(into: &hasher)
    }
    
    public static func == (lhs: AsyncImageProcessor, rhs: AsyncImageProcessor) -> Bool {
        lhs.processorKey == rhs.processorKey
    }
}
