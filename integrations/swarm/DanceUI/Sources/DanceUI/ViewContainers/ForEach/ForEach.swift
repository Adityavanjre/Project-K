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

/// A structure that computes views on demand from an underlying collection of
/// identified data.
///
/// Use `ForEach` to provide views based on a
/// <https://developer.apple.com/documentation/Swift/RandomAccessCollection>
/// of some data type. Either the collection's elements must conform to
/// <https://developer.apple.com/documentation/Swift/Identifiable> or you
/// need to provide an `id` parameter to the `ForEach` initializer.
///
/// The following example creates a `NamedFont` type that conforms to
/// <https://developer.apple.com/documentation/Swift/Identifiable>, and an
/// array of this type called `namedFonts`. A `ForEach` instance iterates
/// over the array, producing new ``Text`` instances that display examples
/// of each DanceUI ``Font`` style provided in the array.
///
///     private struct NamedFont: Identifiable {
///         let name: String
///         let font: Font
///         var id: String { name }
///     }
///
///     private let namedFonts: [NamedFont] = [
///         NamedFont(name: "Large Title", font: .largeTitle),
///         NamedFont(name: "Title", font: .title),
///         NamedFont(name: "Headline", font: .headline),
///         NamedFont(name: "Body", font: .body),
///         NamedFont(name: "Caption", font: .caption)
///     ]
///
///     var body: some View {
///         ForEach(namedFonts) { namedFont in
///             Text(namedFont.name)
///                 .font(namedFont.font)
///         }
///     }
///
@available(iOS 13.0, *)
public struct ForEach<Data: RandomAccessCollection, ID: Hashable, Content> where Data.Index: Hashable {
    
    /// The collection of underlying identified data that DanceUI uses to create
    /// views dynamically.
    public var data: Data
    
    /// A function you can use to create content on demand using the underlying
    /// data.
    public var content: (Data.Element) -> Content
    
    internal var idGenerator: ForEach<Data, ID, Content>.IDGenerator
    
    internal var contentID: Int
    
    private var cachedIDInfos: [Data.Index : _IDInfo] = [:]
    
    internal init(_ data: Data,
                  idGenerator: ForEach<Data, ID, Content>.IDGenerator,
                  content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
        self.idGenerator = idGenerator
        self.contentID = dynamicContentID.generateNextID()
    }
    
    // opt IDGenerator
    internal mutating func makeID(index: Data.Index, offset: Int) -> _IDInfo {
        if let cachedIDInfo = cachedIDInfos[index] {
            return cachedIDInfo
        } else {
            let newID = idGenerator.makeID(data: data, index: index, offset: offset)
            let idInfo = _IDInfo(id: newID, hashValue: newID.hashValue)
            cachedIDInfos[index] = idInfo
            return idInfo
        }
    }
    
    internal enum IDGenerator {
        
        case keyPath(KeyPath<Data.Element, ID>)
        case offset
        
        internal func makeID(data: Data, index: Data.Index, offset: Int) -> ID {
            switch self {
            case .keyPath(let keyPath):
                let element = data[index]
                return element[keyPath: keyPath]
            case .offset:
                return offset as! ID
            }
        }
        
        @inline(__always)
        internal var isConstant: Bool {
            switch self {
            case .keyPath:
                return false
            case .offset:
                return true
            }
        }
    }
    
    internal struct _IDInfo {
        let id: ID
        let hashValue: Int
    }
    
}

@available(iOS 13.0, *)var dynamicContentID = UniqueSeedGenerator()
@available(iOS 13.0, *)
extension ForEach: View, PrimitiveView where Content: View {
    
    public static func _makeView(view: _GraphValue<ForEach<Data, ID, Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        makeImplicitRoot(view: view, inputs: inputs)
    }
    
    public static func _makeViewList(view: _GraphValue<ForEach<Data, ID, Content>>, inputs: _ViewListInputs) -> _ViewListOutputs {
        let state = ForEachState<Data, ID, Content>(inputs: inputs)
        let info = Attribute(ForEachState.Info.Init(view: view.value, state: state))
        state.info = info
        let list = Attribute(ForEachList.Init(info: info, seed: 0))
        state.list = list
        return .init(views: .dynamicList(list, nil), nextImplicitID: inputs.implicitID, staticCount: nil)
    }
}

@available(iOS 13.0, *)
extension ForEach where ID == Data.Element.ID, Content : View, Data.Element : Identifiable {
    
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data.
    ///
    /// It's important that the `id` of a data element doesn't change unless you
    /// replace the data element with a new data element that has a new
    /// identity. If the `id` of a data element changes, the content view
    /// generated from that data element loses any current state and animations.
    ///
    /// - Parameters:
    ///   - data: The identified data that the ``ForEach`` instance uses to
    ///     create views dynamically.
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.init(data, idGenerator: .keyPath(\Data.Element.id), content: content)
    }
}

@available(iOS 13.0, *)
extension ForEach where Content : View {
    
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the provided key path to the underlying data's
    /// identifier.
    ///
    /// It's important that the `id` of a data element doesn't change, unless
    /// DanceUI considers the data element to have been replaced with a new data
    /// element that has a new identity. If the `id` of a data element changes,
    /// then the content view generated from that data element will lose any
    /// current state and animations.
    ///
    /// - Parameters:
    ///   - data: The data that the ``ForEach`` instance uses to create views
    ///     dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.init(data, idGenerator: .keyPath(id), content: content)
    }
}

@available(iOS 13.0, *)
extension ForEach where Data == Range<Int>, ID == Int, Content : View {
    
    /// Creates an instance that computes views on demand over a given constant
    /// range.
    ///
    /// The instance only reads the initial value of the provided `data` and
    /// doesn't need to identify views across updates. To compute views on
    /// demand over a dynamic range, use ``ForEach/init(_:id:content:)``.
    ///
    /// - Parameters:
    ///   - data: A constant range.
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Range<Int>, @ViewBuilder content: @escaping (Int) -> Content) {
        self.init(data, idGenerator: .offset, content: content)
    }
}

@available(iOS 13.0, *)
extension ForEach : DynamicViewContent where Content : View {
    
}
