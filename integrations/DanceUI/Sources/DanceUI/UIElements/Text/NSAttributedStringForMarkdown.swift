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

// NSAttributedStringKeys for markdown

@available(iOS 13.0, *)
public struct InlinePresentationIntent : OptionSet, Hashable, Codable {

    public var rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public func merge(_ type: InlinePresentationIntent) -> InlinePresentationIntent {
        return .init(rawValue: self.rawValue | type.rawValue)
    }
    
    public init(rawValue: Int) {
        self.rawValue = UInt(rawValue)
    }
    
    public init(_ type: InlinePresentationIntent) {
        self.rawValue = type.rawValue
    }
    
    public func hasType(_ type: InlinePresentationIntent) -> Bool {
        return (self.rawValue & type.rawValue) > 0
    }
    
    public static var emphasized: InlinePresentationIntent {
        .init(rawValue: 1)
    }

    public static var stronglyEmphasized: InlinePresentationIntent {
        .init(rawValue: 2)
    }

    public static var code: InlinePresentationIntent {
        .init(rawValue: 4)
    }
    
    public static var strikethrough: InlinePresentationIntent {
        .init(rawValue: 32)
    }

    public static var softBreak: InlinePresentationIntent {
        .init(rawValue: 64)
    }

    public static var lineBreak: InlinePresentationIntent {
        .init(rawValue: 128)
    }

    public static var inlineHTML: InlinePresentationIntent {
        .init(rawValue: 256)
    }

    public static var blockHTML: InlinePresentationIntent {
        .init(rawValue: 512)
    }
}

@available(iOS 13.0, *)
extension NSAttributedString.Key {

    public static let inlinePresentationIntent: NSAttributedString.Key = .init(rawValue: "InlinePresentationIntent")
    
//    public static let alternateDescription: NSAttributedString.Key

    public static let imageURL: NSAttributedString.Key = .init("imageURL")
    
//    public static let languageIdentifier: NSAttributedString.Key

//    public static let replacementIndex: NSAttributedString.Key

    
    // -----
    
    /// If the string has portions tagged with NSInflectionRuleAttributeName
    /// that have no format specifiers, create a new string with those portions inflected
    /// by following the rule in the attribute.

//    public static let morphology: NSAttributedString.Key

//    public static let inflectionRule: NSAttributedString.Key

//    public static let inflectionAlternative: NSAttributedString.Key

    
    public static let presentationIntentAttributeName: NSAttributedString.Key = .init(rawValue: "PresentationIntent")
}

@available(iOS 13.0, *)
internal struct PresentationIntent : Hashable, CustomDebugStringConvertible {

    internal var components: [PresentationIntent.IntentType]

    internal var count: Int {
        components.count
    }

    internal var debugDescription: String {
        components.debugDescription
    }

    public enum Kind : Hashable, CustomDebugStringConvertible {

        case paragraph

        case header(level: Int)

        case orderedList

        case unorderedList

        case listItem(ordinal: Int)

        case codeBlock(languageHint: String?)

        case blockQuote

        case thematicBreak

        case table(columns: [PresentationIntent.TableColumn])

        case tableHeaderRow

        case tableRow(rowIndex: Int)

        case tableCell(columnIndex: Int)

        /// A textual representation of this instance, suitable for debugging.
        ///
        /// Calling this property directly is discouraged. Instead, convert an
        /// instance of any type to a string by using the `String(reflecting:)`
        /// initializer. This initializer works with any type, and uses the custom
        /// `debugDescription` property for types that conform to
        /// `CustomDebugStringConvertible`:
        ///
        ///     struct Point: CustomDebugStringConvertible {
        ///         let x: Int, y: Int
        ///
        ///         var debugDescription: String {
        ///             return "(\(x), \(y))"
        ///         }
        ///     }
        ///
        ///     let p = Point(x: 21, y: 30)
        ///     let s = String(reflecting: p)
        ///     print(s)
        ///     // Prints "(21, 30)"
        ///
        /// The conversion of `p` to a string in the assignment to `s` uses the
        /// `Point` type's `debugDescription` property.
        public var debugDescription: String {
            switch self {
            case .blockQuote: return "blockQuote"
            case .codeBlock(let languageHint): return "codeBlock (languageHint: \(String(describing: languageHint)))"
            case .header(let level): return "header (level: \(level))"
            case .listItem(let ordinal): return "listItem: (ordinal: \(ordinal)"
            case .orderedList: return "orderedList"
            case .paragraph: return "paragraph"
            case .table(let columns): return "table (columns: \(columns))"
            case .tableHeaderRow: return "tableHeaderRow"
            case .unorderedList: return "unorderedList"
            case .thematicBreak: return "thematicBreak"
            case .tableRow(let rowIndex): return "tableRow (rowIndex: \(rowIndex)"
            case .tableCell(let columnIndex): return "tableCell (tableCell: \(columnIndex))"
            }
        }
    }

    public struct TableColumn : Hashable {
        
        public let rawValue: Int

        public enum Alignment : Int, Hashable {

            case left

            case center

            case right

            /// Creates a new instance with the specified raw value.
            ///
            /// If there is no value of the type that corresponds with the specified raw
            /// value, this initializer returns `nil`. For example:
            ///
            ///     enum PaperSize: String {
            ///         case A4, A5, Letter, Legal
            ///     }
            ///
            ///     print(PaperSize(rawValue: "Legal"))
            ///     // Prints "Optional("PaperSize.Legal")"
            ///
            ///     print(PaperSize(rawValue: "Tabloid"))
            ///     // Prints "nil"
            ///
            /// - Parameter rawValue: The raw value to use for the new instance.
            public init?(rawValue: Int) {
                switch rawValue {
                case 0: self = .left
                case 1: self = .center
                case 2: self = .right
                default: return nil
                }
            }

            /// The raw type that can be used to represent all values of the conforming
            /// type.
            ///
            /// Every distinct value of the conforming type has a corresponding unique
            /// value of the `RawValue` type, but there may be values of the `RawValue`
            /// type that don't have a corresponding value of the conforming type.
            public typealias RawValue = Int

            /// The corresponding value of the raw type.
            ///
            /// A new instance initialized with `rawValue` will be equivalent to this
            /// instance. For example:
            ///
            ///     enum PaperSize: String {
            ///         case A4, A5, Letter, Legal
            ///     }
            ///
            ///     let selectedSize = PaperSize.Letter
            ///     print(selectedSize.rawValue)
            ///     // Prints "Letter"
            ///
            ///     print(selectedSize == PaperSize(rawValue: selectedSize.rawValue)!)
            ///     // Prints "true"
            public var rawValue: Int {
                switch self {
                    
                case .left:
                    return 0
                case .center:
                    return 1
                case .right:
                    return 2
                }
            }
        }

        public var alignment: PresentationIntent.TableColumn.Alignment {
            return .init(rawValue: rawValue) ?? .left
        }

        public init(alignment: PresentationIntent.TableColumn.Alignment) {
            self.rawValue = alignment.rawValue
        }
    }

    public struct IntentType : Hashable, CustomDebugStringConvertible {

        public var kind: PresentationIntent.Kind

        public var identity: Int

        /// A textual representation of this instance, suitable for debugging.
        ///
        /// Calling this property directly is discouraged. Instead, convert an
        /// instance of any type to a string by using the `String(reflecting:)`
        /// initializer. This initializer works with any type, and uses the custom
        /// `debugDescription` property for types that conform to
        /// `CustomDebugStringConvertible`:
        ///
        ///     struct Point: CustomDebugStringConvertible {
        ///         let x: Int, y: Int
        ///
        ///         var debugDescription: String {
        ///             return "(\(x), \(y))"
        ///         }
        ///     }
        ///
        ///     let p = Point(x: 21, y: 30)
        ///     let s = String(reflecting: p)
        ///     print(s)
        ///     // Prints "(21, 30)"
        ///
        /// The conversion of `p` to a string in the assignment to `s` uses the
        /// `Point` type's `debugDescription` property.
        public var debugDescription: String {
            kind.debugDescription + "(id \(identity))"
        }
        
        public init(kind: PresentationIntent.Kind, identity: Int) {
            self.kind = kind
            self.identity = identity
        }
        
        public init(_ kind: PresentationIntent.Kind) {
            self.init(kind: kind, identity: 0)
        }
    }

    public init(_ kind: PresentationIntent.Kind, identity: Int, parent: PresentationIntent? = nil) {
        if let parent = parent {
            var components = parent.components
            components.append(IntentType(kind: kind, identity: identity))
            self.components = components
        } else {
            self.components = [IntentType(kind: kind, identity: identity)]
        }
    }

    public init(types: [PresentationIntent.IntentType]) {
        self.components = types
    }
}

@available(iOS 13.0, *)
public enum ParagraphStyle {
    
    case paragraph
    case listItem
    case unorderedList
}
