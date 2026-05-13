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
internal struct PlainDividerColor: _ColorProvider, Equatable, Hashable {
    
    internal func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        
        let colorScheme = environment.colorScheme
        
        if colorScheme == .light {
            return Color.Resolved(linearRed: 0.0451862,
                                   linearGreen: 0.0451862,
                                   linearBlue:0.0561285,
                                   opacity: 0.29)
        }
        
        return Color.Resolved(linearRed: 0.0886556,
                               linearGreen: 0.0886556,
                               linearBlue: 0.0975873,
                               opacity: 0.6)
    }
    
    internal var staticColor: CGColor? {
        nil
    }
}
