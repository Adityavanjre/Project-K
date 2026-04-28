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

import CoreGraphics

@available(iOS 13.0, *)
internal protocol Scrollable {
    

    func scroll<ID: Hashable>(to id: ID, anchor: UnitPoint?) -> Bool
    
    /// DanceUI Extension
    func scroll(to contentOffset: CGPoint) -> Bool
    

    func setContentOffset(target: @escaping ContentOffsetTarget) -> Bool
    

    func adjustContentOffset(by size: CGSize) -> Bool
    
    /// DanceUI Extension
    var contentSize: CGSize? { get }
    
    /// DanceUI Extension
    var contentOffset: CGPoint? { get }
    
    /// DanceUI Extension
    var adjustedContentInset: UIEdgeInsets? { get }
    
    /// DanceUI Extension
    var isDragging: Bool? { get }
    
    /// DanceUI Extension
    func containsScrollable<ID: Hashable>(_ scrollViewID: ID) -> Bool
    
    /// DanceUI Extension
    func scroll<ID: Hashable>(_ scrollViewID: ID, to offset: CGPoint) -> Bool
        
    /// DanceUI Extension
    func getScrollable<ID: Hashable>(of scrollViewID: ID) -> Scrollable?
    
}

internal typealias ContentOffsetTarget = (CGSize, CGRect) -> CGPoint?
