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
@_spi(DanceUICompose) import DanceUI


@available(iOS 13.0, *)
internal class ComposeAsyncImageLoadBinder: NSObject, ComposeAsyncImageLoader {
    
    private lazy var binder = Resolver.services.optional(AsyncImageBinder.self)
    
    internal func requestImage(_ urls: [String]?, options: ComposeImageRequestOptions, config: (any ComposeImageLoadConfig)?, decryptBlock: DanceUIComposeImageLoadDecryptBlock?, progress: DanceUIComposeImageLoadProgressBlock?, complete: @escaping DanceUIComposeImageLoadCompletedBlock) {
        
        Signpost.compose.traceInterval("ComposeAsyncImageLoadBinder:requestImage") {
            Signpost.compose.tracePoi("ComposeAsyncImageLoadBinder:requestImage %d", [urls?.count ?? 0]) {
                let requestURLs = urls?.compactMap(URL.init(string:))
                guard let downloadURL = requestURLs?.first else {
                    let error = NSError(domain: "asyncImage load from empty urls", code: -1, userInfo: [NSLocalizedDescriptionKey: "asyncImage load without urls"])
                    complete(nil, error, nil)
                    return
                }
                
                let context = Set<AsyncImageOption>.from(options: options, config: config)
                let asyncContext = AsyncImageContext(url: downloadURL, alternativeURLs: requestURLs?.dropFirst().map { $0 }, options: context)
                
                let delegate = _AsyncImageDelegate(
                    onSuccessDelegate: { image, eventContext in
                        Signpost.compose.tracePoi("onSuccess", []) {
                            let imageBitmap = ComposeImage(image)
                            complete(imageBitmap, nil,ComposeAsyncImageLoadEventParams(eventContext))
                        }
                    },
                    onProgressDelegate: { received, total in
                        Signpost.compose.tracePoi("onProgress", []) {
                            progress?(Int(received), Int(total))
                        }
                    },
                    onDecryptDelegate: { data in
                        Signpost.compose.tracePoi("onDecrypt", []) {
                            decryptBlock?(data) ?? data
                        }
                    },
                    onFailureDelegate: { error, eventContext in
                        Signpost.compose.tracePoi("onFailure", []) {
                            complete(nil, error, ComposeAsyncImageLoadEventParams(eventContext))
                        }
                    }
                )
                
                Signpost.compose.tracePoi("binder:start", []) {
                    binder?.start(context: asyncContext, delegate: delegate)
                }
            }
        }
    }
    
    internal func cancel() {
        binder?.cancel()
    }
    
}

@available(iOS 13.0, *)
internal class ComposeAsyncImageLoadManager: NSObject, ComposeAsyncImageManager {
    
    internal static let sharedInstance = ComposeAsyncImageLoadManager()

    private lazy var manager = Resolver.services.optional(AsyncImageManager.self)
    
    internal func prefetchImage(_ urls: [String]?) {
        guard let downloadURLs = urls?.compactMap(URL.init(string:)) else {
            return
        }
        
        manager?.prefetch(downloadURLs, cache: .shared)
    }
    
}


@available(iOS 13.0, *)
internal class ComposeAsyncImageLoadEventParams: NSObject, ComposeImageLoadEventParams {
    
    internal var imageType: ComposeImageType
    
    internal var imageSize: CGSize
    
    internal var fileSize: Double
    
    internal var from: ComposeImageLoadFrom
    
    internal var loadDuration: Double
    
    internal var queueDuration: Double
    
    internal var cacheDuration: Double
    
    internal var downloadDuration: Double
    
    internal var decodeDuration: Double
    
    internal var customInfo: [String : Any]
    
    internal init(_ params: AsyncImageEventContext) {
        self.imageType = params.imageType.composeType
        self.imageSize = params.imageSize
        self.fileSize = params.fileSize
        self.from = params.from.composeFrom
        self.loadDuration = params.loadDuration
        self.queueDuration = params.queueDuration
        self.cacheDuration = params.cacheDuration
        self.downloadDuration = params.downloadDuration
        self.decodeDuration = params.decodeDuration
        self.customInfo = params.customInfo
    }
}

internal class ComposeAsyncImageLoadConfig: NSObject, ComposeImageLoadConfig {
    
    internal var timeoutInterval: CFTimeInterval
    
    internal var cacheName: String?
    
    internal var imageDownsampleSize: CGSize
    
    internal var customInfo: [String : Any]?
    
    internal var sceneTag: String?
    
    internal var bizTag: String?
    
    internal var optionValue: Int
    
    internal init(timeoutInterval: CFTimeInterval = 0, cacheName: String? = nil, imageDownsampleSize: CGSize = .zero, customInfo: [String : Any]? = nil, sceneTag: String? = nil, bizTag: String? = nil, optionValue: Int = 0) {
        self.timeoutInterval = timeoutInterval
        self.cacheName = cacheName
        self.imageDownsampleSize = imageDownsampleSize
        self.customInfo = customInfo
        self.sceneTag = sceneTag
        self.bizTag = bizTag
        self.optionValue = optionValue
    }
    
}


@available(iOS 13.0, *)
extension AsyncImageType {
    fileprivate var composeType: ComposeImageType {
        switch self {
        case .unknown:
                .unknown
        case .jpg:
                .JPG
        case .gif:
                .GIF
        case .png:
                .PNG
        case .webp:
                .WEBP
        case .heic:
                .HEIC
        case .avif:
                .AVIF
        }
    }
}

@available(iOS 13.0, *)
extension AsyncImageFrom {
    fileprivate var composeFrom: ComposeImageLoadFrom {
        switch self {
        case .none:
                .none
        case .memory:
                .memory
        case .disk:
                .disk
        case .network:
                .network
        }
    }
}

extension ComposeImageRequestOptions: Hashable {}

@available(iOS 13.0, *)
extension Set where Element == AsyncImageOption {
    
    private static let optionMapping: [ComposeImageRequestOptions: AsyncImageOption] = [
        .lowPriority: .lowPriority,
        .highPriority: .highPriority,
        .ignoreMemoryCache: .ignoreMemoryCache,
        .ignoreDiskCache: .ignoreDiskCache,
        .ignoreNetworkImage: .ignoreNetworkImage,
        .notCacheToMemory: .notCacheToMemery,
        .notCacheToDisk: .notCacheToDisk,
        .noRetry: .notRetry,
        .smartCorp: .imageSmartCorp,
        .disableBackgroundDecode: .imageDisableBackgroundDecode,
        .progressiveDownload: .imageProgressiveDownload
    ]

    fileprivate static func from(options: ComposeImageRequestOptions, config: (any ComposeImageLoadConfig)?) -> Set<AsyncImageOption> {
        var result = Set<AsyncImageOption>()
        result.insert(.defaultPriority)
        
        for (requestOption, asyncOption) in Self.optionMapping {
            if options.contains(requestOption) {
                result.insert(asyncOption)
            }
        }
        
        if let config = config {
            if config.timeoutInterval > 0 {
                result.insert(.timeoutInterval(config.timeoutInterval))
            }
            if let cacheName = config.cacheName {
                result.insert(.cacheName(cacheName))
            }
            if config.imageDownsampleSize != .zero {
                result.insert(.imageDownsample(config.imageDownsampleSize))
            }
            if let customInfo = config.customInfo as? [String: AnyHashable] {
                result.insert(.customInfo(customInfo))
            }
            let sceneTag = config.sceneTag ?? ""
            let bizTag = config.bizTag ?? ""
            if !sceneTag.isEmpty || !bizTag.isEmpty {
                result.insert(.config(_AsyncImageConfig(sceneTag: sceneTag, bizTag: bizTag)))
            }
            if config.optionValue != 0 {
                result.insert(._optionValue(.init(rawValue: config.optionValue)))
            }
        }
        
        return result
    }
}
