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
internal protocol PubliclyPrimitiveView: PrimitiveView {

    associatedtype InternalBody: View

    var internalBody: InternalBody { get }

}

@available(iOS 13.0, *)
extension PubliclyPrimitiveView {
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        defaultMakeView(view: view, inputs: inputs)
    }
    
    public static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        defaultMakeViewList(view: view, inputs: inputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        defaultViewListCount(inputs: inputs)
    }

    internal static func defaultMakeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        let body = MakeBody(view: view.value)
        let graphValue = _GraphValue(body)
        return InternalBody._makeView(view: graphValue, inputs: inputs)
    }
    
    internal static func defaultMakeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        let body = MakeBody(view: view.value)
        let graphValue = _GraphValue(body)
        return InternalBody._makeViewList(view: graphValue, inputs: inputs)
    }
    
    internal static func defaultViewListCount(inputs: _ViewListCountInputs) -> Int? {
        InternalBody._viewListCount(inputs: inputs)
    }
    
}
