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
internal struct ButtonStyleModifier<A: PrimitiveButtonStyle>: StyleModifier {
    
    internal typealias Body = Never
    
    internal typealias Style = A
    
    internal typealias Subject = ResolvedButtonStyle
    
    internal typealias SubjectBody = A.Body
    
    internal var style: Style
    
    internal static func body(view: Subject, style: Style) -> SubjectBody {
        style.makeBody(configuration: view.configuration)
    }
    
}
