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

internal import Resolver

@available(iOS 13.0, *)
public struct StandardAsyncImageInner : AsyncImageInner, ServiceRegister {
    
    public static func _makeView<Content>(view: _GraphValue<AsyncImage<Content>>, inputs: _ViewInputs) -> _ViewOutputs where Content : View {
        return Child<Content>.Value._makeView(view: _GraphValue(Child(asyncImage: view.value)), inputs: inputs)
    }
    
    public static func _makeViewList<Content>(view: _GraphValue<AsyncImage<Content>>, inputs: _ViewListInputs) -> _ViewListOutputs where Content : View {
        return Child<Content>.Value._makeViewList(view: _GraphValue(Child(asyncImage: view.value)), inputs: inputs)
    }
    
    public init() {}
    
    @_silgen_name("DanceUIExtension.AsyncImage.StandardAsyncImageInner")
    public static func register() {
        Resolver.services.register {
            StandardAsyncImageInner() as AsyncImageInner
        }.scope(.shared)
        
        Resolver.services.register {
            StandardAsyncImageManager.shared as AsyncImageManager
        }.scope(.shared)
        
        Resolver.services.register {
            StandardAsyncImageBinder() as AsyncImageBinder
        }.scope(.unique)
    }

    fileprivate struct Child<Content : View> : Rule {
        
        fileprivate typealias Value = _StandardAsyncImage<Content>
        
        @Attribute
        fileprivate var asyncImage: AsyncImage<Content>
        
        fileprivate var value: Value {
            let image = asyncImage
            return _StandardAsyncImage(url: image.url,
                                       scale: image.scale,
                                       transaction: image.transaction,
                                       content: image.content)
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct LoadingState {

    fileprivate var binder: StandardAsyncImageBinder?
    
    fileprivate var url: URL?

    fileprivate var phase: AsyncImagePhase

    fileprivate init() {
        binder = nil
        url = nil
        phase = .empty
    }
}

@available(iOS 13.0, *)
internal struct _StandardAsyncImage<Content : View>: View {

    internal var url: URL?

    internal var scale: CGFloat

    internal var transaction: Transaction

    internal var content: (AsyncImagePhase) -> Content

    internal init(url: URL?, scale: CGFloat = 1, transaction: Transaction = Transaction(), @ViewBuilder content: @escaping (AsyncImagePhase, AsyncImageEventContext?) -> Content) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = { phase in
            content(phase, nil)
        }
        self._loadingState = State(wrappedValue: LoadingState())
    }

    @State
    fileprivate var loadingState: LoadingState

    fileprivate func load(_ url: URL?) {
        switch loadingState.phase {
        case .empty: break
        default:
            if loadingState.url == url {
                return
            }
        }
        if let binder = loadingState.binder {
            binder.cancel()
            loadingState.binder = nil
            loadingState.url = nil
        }
        if let downloadUrl = url {
            let binder = StandardAsyncImageBinder()
            let context = AsyncImageContext(url: downloadUrl, scale: scale)
            let delegate = _AsyncImageDelegate(
                onSuccessDelegate: { image, _ in
                    withTransaction(transaction) {
                        loadingState.phase = .success(image)
                    }
                },
                onFailureDelegate: { error, _ in
                    withTransaction(transaction) {
                        loadingState.phase = .failure(error ?? LoadingError())
                    }
                },
                onResetDelegate: {
                    withTransaction(transaction) {
                        loadingState.phase = .empty
                    }
                }
            )
            binder.start(context: context, delegate: delegate)
            loadingState.binder = binder
            loadingState.url = downloadUrl
        }
    }

    internal var body: some View {
        _UnaryViewAdaptor(content(loadingState.phase))
            .onChange(of: url, initial: true) { _, new in
                load(new)
            }
            .onDisappear {
                loadingState.binder?.cancel()
            }
    }

}
