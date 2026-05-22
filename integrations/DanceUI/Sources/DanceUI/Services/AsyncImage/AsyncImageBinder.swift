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
public struct AsyncImageContext : Equatable {
    
    public let url: URL?
    public let alternativeURLs: [URL]?
    public let scale: CGFloat
    public let options: Set<AsyncImageOption>
    /// Specify business passthrough info
    public let userInfo: Any?
    
    public init(url: URL?, alternativeURLs: [URL]? = nil, scale: CGFloat = 1, options: Set<AsyncImageOption> = Set(), userInfo: Any? = nil) {
        self.url = url
        self.alternativeURLs = alternativeURLs
        self.scale = scale
        self.options = options
        self.userInfo = userInfo
    }
    
    public static func == (lhs: AsyncImageContext, rhs: AsyncImageContext) -> Bool {
        lhs.url == rhs.url &&
        lhs.alternativeURLs == rhs.alternativeURLs &&
        lhs.scale == rhs.scale &&
        lhs.options == rhs.options
    }
}

@available(iOS 13.0, *)
public struct _AsyncImageDelegate {
    public var onSuccessDelegate: ((Image, AsyncImageEventContext) -> Void)?
    public var onProgressDelegate: ((Int64, Int64) -> Void)?
    public var onDecryptDelegate: ((Data?) -> Data?)?
    public var onFailureDelegate: ((Error?, AsyncImageEventContext) -> Void)?
    public var onResetDelegate: (() -> Void)?
    
    public init(onSuccessDelegate: ((Image, AsyncImageEventContext) -> Void)? = nil,
                onProgressDelegate: ((Int64, Int64) -> Void)? = nil,
                onDecryptDelegate: ((Data?) -> Data?)? = nil,
                onFailureDelegate: (((any Error)?, AsyncImageEventContext) -> Void)? = nil,
                onResetDelegate: (() -> Void)? = nil) {
        self.onSuccessDelegate = onSuccessDelegate
        self.onProgressDelegate = onProgressDelegate
        self.onDecryptDelegate = onDecryptDelegate
        self.onFailureDelegate = onFailureDelegate
        self.onResetDelegate = onResetDelegate
    }
}

@available(iOS 13.0, *)
public protocol AsyncImageBinder {
    init()
    func start(context: AsyncImageContext, delegate: _AsyncImageDelegate)
    func cancel()
    static var imageManager: AsyncImageManager { get }
}

@available(iOS 13.0, *)
fileprivate struct AsyncImageBinderKey: EnvironmentKey {
    
    fileprivate typealias Value = AsyncImageBinder.Type?
    
    fileprivate static var defaultValue: Value {
        nil
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    internal var imageBinderType: AsyncImageBinder.Type? {
        get {
            self[AsyncImageBinderKey.self]
        }
        set {
            self[AsyncImageBinderKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
@_spi(DanceUIExtension)
extension View {
    public func imageBinder(_ type: AsyncImageBinder.Type) -> some View {
        environment(\.imageBinderType, type)
    }
}
