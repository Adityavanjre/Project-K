//
//  ComposeParagraphPlaceholderImpl.swift
//  DanceUICompose
//
//  Created by 万圣 on 2026/2/2.
//
//  module: Compose

import Foundation

internal final class ComposeParagraphPlaceholderImpl: NSObject, ComposeParagraphPlaceholder {
    
    internal var width: CGFloat
    internal var height: CGFloat
    internal var alignment: PlaceholderVerticalAlign
    
    @objc init(width: CGFloat, height: CGFloat, alignment: Int32) {
        self.width = width
        self.height = height
        self.alignment = .init(rawValue: alignment - 1) ?? .aboveBaseline
    }
    
}

internal enum PlaceholderVerticalAlign: Int32 {
    case aboveBaseline
    case top
    case bottom
    case center
    case textTop
    case textBottom
    case textCenter
}
