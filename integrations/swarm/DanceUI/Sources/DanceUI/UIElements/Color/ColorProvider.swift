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
import UIKit

@available(iOS 13.0, *)
public protocol ColorProvider: Hashable {
    
    func resolve(in environment: EnvironmentValues) -> Color
}

@available(iOS 13.0, *)
extension Color {
    
    fileprivate struct PublicColorProvider<P: ColorProvider> : _ColorProvider {
        
        private let provider: P
        
        internal init(provider: P) {
            self.provider = provider
        }
        
        fileprivate func resolve(in environment: EnvironmentValues) -> Color.Resolved {
            let color = provider.resolve(in: environment)
            return color._box.resolve(in: environment)
        }
        
        fileprivate var staticColor: CGColor? {
            nil
        }
    }
    
    /// Specify an instance that conforms to the ColorProvider protocol to
    /// customize the color processing logic.
    public init<Provider: ColorProvider>(_ provider: Provider) {
        self._box = ColorBox(provider: PublicColorProvider(provider: provider))
    }
    
    fileprivate struct ColorResolveProvider: _ColorProvider {
        
        let id: UUID
        
        let body: (EnvironmentValues) -> Color
        
        fileprivate init(id: UUID = UUID(), 
                         body: @escaping (EnvironmentValues) -> Color) {
            self.id = id
            self.body = body
        }
        
        fileprivate func resolve(in environment: EnvironmentValues) -> Color.Resolved {
            let color = body(environment)
            return color._box.resolve(in: environment)
        }
        
        static func == (lhs: Color.ColorResolveProvider, rhs: Color.ColorResolveProvider) -> Bool {
            DGCompareValues(lhs: lhs, rhs: rhs)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        fileprivate var staticColor: CGColor? {
            nil
        }
    }
    
    /// Specify a closure to customize the Color processing logic
    /// by returning an Color via an EnvironmentValue.
    public init(_ resolveColor: @escaping (EnvironmentValues) -> Color) {
        self._box = ColorBox(provider: ColorResolveProvider(body: resolveColor))
    }
}
