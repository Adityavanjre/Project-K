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
internal import DanceUIRuntime

@available(iOS 13.0, *)
public protocol ImageProvider: Equatable {
    
    func resolve(in environment: EnvironmentValues) -> Image
}

@available(iOS 13.0, *)
extension ImageProvider {
    func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
        let image = self.resolve(in: environment)
        return image.provider.resolve(in: environment, style: style)
    }
}

@available(iOS 13.0, *)
extension Image {
    
    fileprivate struct PublicImageProvider<P: ImageProvider> : _ImageProvider {
        
        private let provider: P
        
        internal init(provider: P) {
            self.provider = provider
        }
        
        fileprivate func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            provider.resolve(in: environment, style: style)
        }
        
        fileprivate var staticImage: UIImage? {
            nil
        }
    }
    
    /// Specify an instance that conforms to the ImageProvider protocol to
    /// customize the Image processing logic.
    public init<Provider: ImageProvider>(_ provider: Provider) {
        self.provider = ImageProviderBox(PublicImageProvider(provider: provider))
    }
    
    fileprivate struct ImageResolveProvider: _ImageProvider {
        
        let body: (EnvironmentValues) -> Image
        
        func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            let image = body(environment)
            return image.provider.resolve(in: environment, style: style)
        }
        
        static func == (lhs: Image.ImageResolveProvider, rhs: Image.ImageResolveProvider) -> Bool {
            DGCompareValues(lhs: lhs.body, rhs: rhs.body)
        }
        
        fileprivate var staticImage: UIImage? {
            nil
        }
    }
    
    /// Specify a closure to customize the Image processing logic
    /// by returning an Image via an EnvironmentValue.
    public init(_ resolveImage: @escaping (EnvironmentValues) -> Image) {
        self.provider = ImageProviderBox(ImageResolveProvider(body: resolveImage))
    }
}
