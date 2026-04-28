//
//  ComposeAnnotatedStringRangeWithPlaceHolderImpl.swift
//  DanceUICompose
//
//  Created by 万圣 on 2026/2/2.
//
//  module: Compose

import Foundation
import UIKit

@available(iOS 13.0, *)
internal class ComposeAnnotatedStringRangeWithPlaceHolderImpl: NSObject, ComposeAnnotatedStringRangeWithPlaceholder {
    internal var range: NSRange
    internal var placeholder: any ComposeParagraphPlaceholder

    internal init(range: NSRange, placeholder: any ComposeParagraphPlaceholder) {
        self.range = range
        self.placeholder = placeholder
    }
}
