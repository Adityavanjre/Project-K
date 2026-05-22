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
internal struct AsyncImagePhaseContext: Equatable {
    
    internal var event: AsyncImageEventContext
    
    internal var phase: AsyncImagePhase
    
    internal init(phase: AsyncImagePhase) {
        self.event = .init()
        self.phase = phase
    }
    
    internal init(event: AsyncImageEventContext, phase: AsyncImagePhase) {
        self.event = event
        self.phase = phase
    }
    
    internal static var empty: AsyncImagePhaseContext {
        .init(phase: .empty)
    }
    
    internal static func == (lhs: AsyncImagePhaseContext, rhs: AsyncImagePhaseContext) -> Bool {
        switch (lhs.phase, rhs.phase) {
        case (.empty, .empty):
            return true
        case (.success(let image1), .success(let image2)):
            return image1 == image2
        case (.failure(_), .failure(_)):
            return true
        default:
            return false
        }
    }
}

@available(iOS 13.0, *)
public struct AsyncImageEventContext {
    public var imageType: AsyncImageType
    public var imageSize: CGSize
    public var fileSize: Double
    public var from: AsyncImageFrom
    public var loadDuration: Double
    public var queueDuration: Double
    public var cacheDuration: Double
    public var downloadDuration: Double
    public var decodeDuration: Double
    public var customInfo: [String:AnyHashable]
    
    public init() {
        imageType = .unknown
        imageSize = .zero
        fileSize = 0
        from = .none
        loadDuration = 0
        queueDuration = 0
        cacheDuration = 0
        downloadDuration = 0
        decodeDuration = 0
        customInfo = [:]
    }
    
    public init(imageType: AsyncImageType,
                imageSize: CGSize,
                fileSize: Double,
                from: AsyncImageFrom,
                loadDuration: Double,
                queueDuration: Double,
                cacheDuration: Double,
                downloadDuration: Double,
                decodeDuration: Double,
                customInfo: [String:AnyHashable] = [:]) {
        self.imageType = imageType
        self.imageSize = imageSize
        self.fileSize = fileSize
        self.from = from
        self.loadDuration = loadDuration
        self.queueDuration = queueDuration
        self.cacheDuration = cacheDuration
        self.downloadDuration = downloadDuration
        self.decodeDuration = decodeDuration
        self.customInfo = customInfo
    }
}

@frozen
@available(iOS 13.0, *)
public enum AsyncImageType {
    case unknown
    case jpg
    case gif
    case png
    case webp
    case heic
    case avif
}

@frozen
@available(iOS 13.0, *)
public enum AsyncImageFrom {
    case none
    case memory
    case disk
    case network
}

@frozen
@available(iOS 13.0, *)
public enum AsyncImageLoadedStatus {
    case success
    case failure
}

@available(iOS 13.0, *)
extension AsyncImage {
    
    public init(url: URL?, alternativeURLs: [URL] = [], scale: CGFloat = 1, transaction: Transaction = Transaction(), @ViewBuilder contextContent: @escaping (AsyncImagePhase, AsyncImageEventContext?) -> Content) {
        self.url = url
        self.alternativeURLs = alternativeURLs
        self.scale = scale
        self.transaction = transaction
        self.content = contextContent
    }
}
