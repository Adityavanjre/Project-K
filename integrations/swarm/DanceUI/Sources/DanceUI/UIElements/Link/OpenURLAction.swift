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
public struct OpenURLAction {
    
    /// The result of a custom open URL action.
    ///
    /// If you declare a custom ``OpenURLAction`` in the ``Environment``,
    /// return one of the result values from its handler.
    ///
    /// * Use ``handled`` to indicate that the handler opened the URL.
    /// * Use ``discarded`` to indicate that the handler discarded the URL.
    /// * Use ``systemAction`` without an argument to ask DanceUI
    ///   to open the URL with the system handler.
    /// * Use ``systemAction(_:)`` with a URL argument to ask DanceUI
    ///   to open the specified URL with the system handler.
    ///
    /// You can use the last option to transform URLs, while
    /// still relying on the system to open the URL. For example,
    /// you could append a path component to every URL:
    ///
    ///     .environment(\.openURL, OpenURLAction { url in
    ///         .systemAction(url.appendingPathComponent("edit"))
    ///     })
    ///
    public struct Result {

        public enum ActionResult {

            case systemAction(url: URL?)

            case handled

            case discarded

        }
        
        internal var actionResult: ActionResult
        
        /// The handler opened the URL.
        ///
        /// The action invokes its completion handler with `true` when your
        /// handler returns this value.
        public static let handled = Result(actionResult: .handled)

        /// The handler discarded the URL.
        ///
        /// The action invokes its completion handler with `false` when your
        /// handler returns this value.
        public static let discarded = Result(actionResult: .discarded)

        /// The handler asks the system to open the original URL.
        ///
        /// The action invokes its completion handler with a value that
        /// depends on the outcome of the system's attempt to open the URL.
        public static let systemAction = Result(actionResult: .systemAction(url: nil))

        /// The handler asks the system to open the modified URL.
        ///
        /// The action invokes its completion handler with a value that
        /// depends on the outcome of the system's attempt to open the URL.
        ///
        /// - Parameter url: The URL that the handler asks the system to open.
        public static func systemAction(_ url: URL) -> Result {
            Result(actionResult: .systemAction(url: url))
        }

    }
    
    internal enum Handler {

        case system((URL, @escaping (Bool) -> Void) -> Void)

        case custom((URL) -> Result, fallback: ((URL, (Bool) -> Void) -> Void)?)

    }
    
    internal let handler: Handler
    
    internal let isDefault: Bool
    
    @inline(__always)
    internal init(handler: Handler, isDefault: Bool) {
        self.handler = handler
        self.isDefault = isDefault
    }
    
    @inline(__always)
    internal init(handler: @escaping (URL, @escaping (Bool) -> Void) -> Void, isDefault: Bool) {
        self.init(handler: .system(handler), isDefault: isDefault)
    }
    
    /// Creates an action that opens a URL.
    ///
    /// Use this initializer to create a custom action for opening URLs.
    /// Provide a handler that takes a URL and returns an
    /// ``OpenURLAction/Result``. Place your handler in the environment
    /// using the ``View/environment(_:_:)`` view modifier:
    ///
    ///     Text("Visit [Example Company](https://www.example.com) for details.")
    ///         .environment(\.openURL, OpenURLAction { url in
    ///             handleURL(url) // Define this method to take appropriate action.
    ///             return .handled
    ///         })
    ///
    /// Any views that read the action from the environment, including the
    /// built-in ``Link`` view and ``Text`` views with markdown links, or
    /// links in attributed strings, use your action.
    ///
    /// DanceUI translates the value that your custom action's handler
    /// returns into an appropriate Boolean result for the action call.
    /// For example, a view that uses the action declared above
    /// receives `true` when calling the action, because the
    /// handler always returns ``OpenURLAction/Result/handled``.
    ///
    /// - Parameter handler: The closure to run for the given URL.
    ///   The closure takes a URL as input, and returns a ``Result``
    ///   that indicates the outcome of the action.
    public init(handler: @escaping (URL) -> Result) {
        self.init(handler: .custom(handler, fallback: nil), isDefault: true)
    }

    /// Opens a URL, following system conventions.
    ///
    /// Don't call this method directly. DanceUI calls it when you
    /// call the ``OpenURLAction`` structure that you get from the
    /// ``Environment``, using a URL as an argument:
    ///
    ///     struct OpenURLExample: View {
    ///         @Environment(\.openURL) private var openURL
    ///
    ///         var body: some View {
    ///             Button {
    ///                 if let url = URL(string: "https://www.example.com") {
    ///                     openURL(url) // Implicitly calls openURL.callAsFunction(url)
    ///                 }
    ///             } label: {
    ///                 Label("Get Help", systemImage: "person.fill.questionmark")
    ///             }
    ///         }
    ///     }
    ///
    /// For information about how Swift uses the `callAsFunction()` method to
    /// simplify call site syntax, see
    /// [Methods with Special Names](https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID622)
    /// in *The Swift Programming Language*.
    ///
    /// - Parameter url: The URL to open.
    public func callAsFunction(_ url: URL, completion: @escaping (_ accepted: Bool) -> Void) {
        _open(url, completion: completion)
    }
    
    /// Asynchronously opens a URL, following system conventions.
    ///
    /// Don't call this method directly. DanceUI calls it when you
    /// call the ``OpenURLAction`` structure that you get from the
    /// ``Environment``, using a URL and a completion handler as arguments:
    ///
    ///     struct OpenURLExample: View {
    ///         @Environment(\.openURL) private var openURL
    ///
    ///         var body: some View {
    ///             Button {
    ///                 if let url = URL(string: "https://www.example.com") {
    ///                     // Implicitly calls openURL.callAsFunction(url) { ... }
    ///                     openURL(url) { accepted in
    ///                         print(accepted ? "Success" : "Failure")
    ///                     }
    ///                 }
    ///             } label: {
    ///                 Label("Get Help", systemImage: "person.fill.questionmark")
    ///             }
    ///         }
    ///     }
    ///
    /// For information about how Swift uses the `callAsFunction()` method to
    /// simplify call site syntax, see
    /// [Methods with Special Names](https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID622)
    /// in *The Swift Programming Language*.
    ///
    /// - Parameters:
    ///   - url: The URL to open.
    ///   - completion: A closure the method calls after determining if
    ///     it can open the URL, but possibly before fully opening the URL.
    ///     The closure takes a Boolean value that indicates whether the
    ///     method can open the URL.
    @available(watchOS, unavailable)
    public func callAsFunction(_ url: URL) {
        _open(url, completion: { _ in })
    }
    
    private func _open(_ url: URL, completion: @escaping (Bool) -> Void) {
        switch handler {
        case .system(let systemHandler):
            // case = 0
            if url.isFileURL {
                completion(false)
            } else {
                systemHandler(url, completion)
            }
            break
        case .custom(let customHandler, fallback: let fallbackHandler):
            let result = customHandler(url)
            
            switch result.actionResult {
            case .handled:
                completion(true)
            case .discarded:
                completion(false)
            case .systemAction(let urlOrNil):
                let handler = fallbackHandler ?? OpenURLActionKey.defaultValue._open
                handler(urlOrNil ?? url, completion)
            }
        }
    }
    
}

@available(iOS 13.0, *)
private struct OpenURLActionKey: EnvironmentKey {
    
    fileprivate typealias Value = OpenURLAction
    
    fileprivate static var defaultValue: Value {
        OpenURLAction(handler: .system({ url, completion in
            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: completion)
        }), isDefault: true)
    }
    
}

@available(iOS 13.0, *)
// TODO: HostingViewOpenURLActionKey

// TODO: OpenSensitiveURLActionKey

extension EnvironmentValues {

    /// An action that opens a URL.
    ///
    /// Read this environment value to get an ``OpenURLAction``
    /// instance for a given ``Environment``. Call the
    /// instance to open a URL. You call the instance directly because it
    /// defines a ``OpenURLAction/callAsFunction(_:)`` method that Swift
    /// calls when you call the instance.
    ///
    /// For example, you can open a web site when the user taps a button:
    ///
    ///     struct OpenURLExample: View {
    ///         @Environment(\.openURL) private var openURL
    ///
    ///         var body: some View {
    ///             Button {
    ///                 if let url = URL(string: "https://www.example.com") {
    ///                     openURL(url)
    ///                 }
    ///             } label: {
    ///                 Label("Get Help", systemImage: "person.fill.questionmark")
    ///             }
    ///         }
    ///     }
    ///
    /// If you want to know whether the action succeeds, add a completion
    /// handler that takes a Boolean value. In this case, Swift implicitly
    /// calls the ``OpenURLAction/callAsFunction(_:completion:)`` method
    /// instead. That method calls your completion handler after it determines
    /// whether it can open the URL, but possibly before it finishes opening
    /// the URL. You can add a handler to the example above so that
    /// it prints the outcome to the console:
    ///
    ///     openURL(url) { accepted in
    ///         print(accepted ? "Success" : "Failure")
    ///     }
    ///
    /// The system provides a default open URL action with behavior
    /// that depends on the contents of the URL. For example, the default
    /// action opens a Universal Link in the associated app if possible,
    /// or in the user’s default web browser if not.
    ///
    /// You can also set a custom action using the ``View/environment(_:_:)``
    /// view modifier. Any views that read the action from the environment,
    /// including the built-in ``Link`` view and ``Text`` views with markdown
    /// links, or links in attributed strings, use your action. Initialize an
    /// action by calling the ``OpenURLAction/init(handler:)`` initializer with
    /// a handler that takes a URL and returns an ``OpenURLAction/Result``:
    ///
    ///     Text("Visit [Example Company](https://www.example.com) for details.")
    ///         .environment(\.openURL, OpenURLAction { url in
    ///             handleURL(url) // Define this method to take appropriate action.
    ///             return .handled
    ///         })
    ///
    /// DanceUI translates the value that your custom action's handler
    /// returns into an appropriate Boolean result for the action call.
    /// For example, a view that uses the action declared above
    /// receives `true` when calling the action, because the
    /// handler always returns ``OpenURLAction/Result/handled``.
    public var openURL: OpenURLAction {
        get {
            self[OpenURLActionKey.self]
        }
        set {
            self[OpenURLActionKey.self] = newValue
        }
    }
    
}
